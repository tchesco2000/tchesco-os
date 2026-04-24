#!/usr/bin/env bash
# Reconstrói a ISO Tchesco OS com boot EFI+BIOS correto
# Estratégia: squashfs fica inteiramente no D: (loop image) — disco local só guarda ~700MB
set -euo pipefail

KUBUNTU_ISO="/media/sf_D_DRIVE/Downloads/kubuntu-26.04-desktop-amd64.iso"
BOOT_ISO="/media/sf_D_DRIVE/tchesco-os-1.0-BOOT.iso"
OUTPUT_ISO="/media/sf_D_DRIVE/tchesco-os-1.0-amd64.iso"
OUTPUT_SQUASHFS="/media/sf_D_DRIVE/tchesco-fixed.squashfs"
BUILD_DIR="/var/tmp/iso-build"        # só arquivos pequenos (~700MB) no disco local
MBR_IMG="/var/tmp/kubuntu-mbr.img"
EFI_IMG="/var/tmp/kubuntu-efi.img"
SQUASH_LOOP="/media/sf_D_DRIVE/squash-fix.img"   # 15GB no D: para unsquash+resquash
SQUASH_MNT="/mnt/squash-fix"

# ─── Limpeza ──────────────────────────────────────────────────────────────────
echo "[1/7] Limpeza..."
umount "$SQUASH_MNT" 2>/dev/null || true
rm -f "$SQUASH_LOOP" "$OUTPUT_SQUASHFS"
rm -f "$MBR_IMG" "$EFI_IMG"
rm -rf "$BUILD_DIR"
df -h / | tail -1

# ─── MBR + EFI via Python ─────────────────────────────────────────────────────
echo "[2/7] Extraindo MBR e EFI via Python..."
python3 - << 'PYEOF'
with open("/media/sf_D_DRIVE/Downloads/kubuntu-26.04-desktop-amd64.iso", "rb") as f:
    mbr = f.read(432)
    f.seek(9889132 * 512)
    efi = f.read(10296 * 512)
with open("/var/tmp/kubuntu-mbr.img", "wb") as f: f.write(mbr)
with open("/var/tmp/kubuntu-efi.img", "wb") as f: f.write(efi)
print(f"MBR: {len(mbr)} bytes  EFI: {len(efi)} bytes")
PYEOF
ls -lh "$MBR_IMG" "$EFI_IMG"

# ─── Monta ISOs ───────────────────────────────────────────────────────────────
echo "[3/7] Montando ISOs..."
mkdir -p /mnt/kub-iso /mnt/boot-iso "$SQUASH_MNT"
mount -o loop,ro "$KUBUNTU_ISO" /mnt/kub-iso  || true
mount -o loop,ro "$BOOT_ISO"    /mnt/boot-iso || true
ls -lh /mnt/boot-iso/casper/filesystem.squashfs

# ─── Loop image no D: para o squashfs ─────────────────────────────────────────
echo "[4/7] Criando loop image 15GB no D: para operações squashfs..."
truncate -s 15G "$SQUASH_LOOP"
mkfs.ext4 -F "$SQUASH_LOOP" >> /var/log/tchesco-rebuild.log 2>&1
mount -o loop "$SQUASH_LOOP" "$SQUASH_MNT"
echo "Loop montado: $(df -h "$SQUASH_MNT" | tail -1)"

# ─── Unsquash → fix → resquash (tudo no D:) ───────────────────────────────────
echo "[5/7] Extraindo squashfs no D: (~5 min)..."
unsquashfs -d "$SQUASH_MNT/fs" /mnt/boot-iso/casper/filesystem.squashfs >> /var/log/tchesco-rebuild.log 2>&1

echo "[5b] Corrigindo usuário live e SDDM..."

# Senha live: tchesco:tchesco
chroot "$SQUASH_MNT/fs" bash -c "echo 'ubuntu:tchesco' | chpasswd" 2>/dev/null || true

# SDDM autologin
cat > "$SQUASH_MNT/fs/etc/sddm.conf.d/30-tchesco-x11.conf" << 'SDDMEOF'
[Autologin]
User=ubuntu
Session=plasmax11

[X11]
MinimumVT=1
SDDMEOF

# Plymouth: remove WhiteSur, força breeze-text
chroot "$SQUASH_MNT/fs" bash -c "
    rm -rf /usr/share/plymouth/themes/whitesur* 2>/dev/null || true
    if update-alternatives --list default.plymouth 2>/dev/null | grep -q breeze-text; then
        update-alternatives --set default.plymouth /usr/share/plymouth/themes/breeze-text/breeze-text.plymouth
    fi
    update-initramfs -u 2>/dev/null || true
" >> /var/log/tchesco-rebuild.log 2>&1

# Instala o Tchesco Welcome
echo "[5b2] Instalando Tchesco Welcome..."
mkdir -p "$SQUASH_MNT/fs/opt/tchesco-setup"
WELCOME_SRC="$(find /home /root -name "tchesco-welcome" -path "*/setup/welcome/*" 2>/dev/null | head -1 | xargs dirname)"
cp "$WELCOME_SRC/tchesco-welcome"                      "$SQUASH_MNT/fs/opt/tchesco-setup/"
cp "$WELCOME_SRC/tchesco-welcome.desktop"              "$SQUASH_MNT/fs/opt/tchesco-setup/"
cp "$WELCOME_SRC/tchesco-welcome-autostart.desktop"    "$SQUASH_MNT/fs/opt/tchesco-setup/"
cp "$WELCOME_SRC/install-welcome.sh"                   "$SQUASH_MNT/fs/opt/tchesco-setup/"

chroot "$SQUASH_MNT/fs" bash /opt/tchesco-setup/install-welcome.sh >> /var/log/tchesco-rebuild.log 2>&1

# Copia configs KDE do ubuntu para /etc/skel (garante tema no live)
echo "[5b3] Sincronizando configs KDE para /etc/skel..."
for dir in .config .local/share/plasma .local/share/color-schemes; do
    if [[ -d "$SQUASH_MNT/fs/home/ubuntu/$dir" ]]; then
        mkdir -p "$SQUASH_MNT/fs/etc/skel/$dir"
        rsync -a "$SQUASH_MNT/fs/home/ubuntu/$dir/" "$SQUASH_MNT/fs/etc/skel/$dir/" 2>/dev/null || true
    fi
done

# Calamares: garante branding tchesco
CALAMARES_CONF="$SQUASH_MNT/fs/etc/calamares/settings.conf"
if [[ -f "$CALAMARES_CONF" ]]; then
    sed -i 's/branding: kubuntu/branding: tchesco/g' "$CALAMARES_CONF"
    sed -i 's/branding: ubuntu/branding: tchesco/g' "$CALAMARES_CONF"
    echo "Calamares branding: tchesco"
fi

echo "[5c] Recomprimindo squashfs → D: (~15 min)..."
mksquashfs "$SQUASH_MNT/fs" "$OUTPUT_SQUASHFS" -comp gzip -noappend
echo "squashfs: $(ls -lh "$OUTPUT_SQUASHFS" | awk '{print $5}')"

umount "$SQUASH_MNT"
rm -f "$SQUASH_LOOP"

# ─── Diretório de build local (só ~700MB) ─────────────────────────────────────
echo "[6/7] Preparando build dir local (exceto squashfs)..."
mkdir -p "$BUILD_DIR/casper"
rsync -a --exclude="casper/filesystem.squashfs" /mnt/kub-iso/ "$BUILD_DIR/"
echo "rsync: $(du -sh "$BUILD_DIR" | cut -f1)"

# Corrige GRUB labels
sed -i 's/Try or Install Kubuntu/Try or Install Tchesco OS/g' "$BUILD_DIR/boot/grub/grub.cfg"
sed -i 's/Kubuntu (safe graphics)/Tchesco OS (safe graphics)/g' "$BUILD_DIR/boot/grub/grub.cfg"
sed -i 's/Try or Install Kubuntu/Try or Install Tchesco OS/g' "$BUILD_DIR/boot/grub/loopback.cfg" 2>/dev/null || true
sed -i 's/Kubuntu (safe graphics)/Tchesco OS (safe graphics)/g' "$BUILD_DIR/boot/grub/loopback.cfg" 2>/dev/null || true
df -h / | tail -1

# ─── xorriso com graft-point para squashfs no D: ──────────────────────────────
echo "[7/7] Gerando ISO bootável..."
xorriso -as mkisofs \
    -r -J \
    -iso-level 3 \
    --grub2-mbr "$MBR_IMG" \
    --protective-msdos-label \
    -partition_cyl_align off \
    -partition_offset 16 \
    --mbr-force-bootable \
    -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b "$EFI_IMG" \
    -appended_part_as_gpt \
    -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
    -c /boot.catalog \
    -b /boot/grub/i386-pc/eltorito.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --grub2-boot-info \
    -eltorito-alt-boot \
    -e '--interval:appended_partition_2_start_0s_size_10296d:all::' \
    -no-emul-boot \
    -boot-load-size 10296 \
    -V TCHESCO_OS_1_0 \
    -o "$OUTPUT_ISO" \
    -graft-points \
    "$BUILD_DIR" \
    "casper/filesystem.squashfs=$OUTPUT_SQUASHFS"

echo ""
echo "=== Verificação ==="
isoinfo -d -i "$OUTPUT_ISO" 2>/dev/null | grep -iE "Torito|Joliet|Volume"
file "$OUTPUT_ISO"
ls -lh "$OUTPUT_ISO"
md5sum "$OUTPUT_ISO"

echo ""
echo "=== Cleanup ==="
umount /mnt/kub-iso /mnt/boot-iso 2>/dev/null || true
rm -rf "$BUILD_DIR" "$MBR_IMG" "$EFI_IMG" "$OUTPUT_SQUASHFS"
echo "Feito!"
