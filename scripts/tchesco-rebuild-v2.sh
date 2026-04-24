#!/usr/bin/env bash
# Tchesco OS — Rebuild definitivo da ISO
# Copia configs KDE reais da VM, corrige Plymouth no initrd, remove plasma-welcome
set -euo pipefail

KUBUNTU_ISO="/media/sf_D_DRIVE/Downloads/kubuntu-26.04-desktop-amd64.iso"
BOOT_ISO="/media/sf_D_DRIVE/tchesco-os-1.0-FINAL.iso"
OUTPUT_ISO="/media/sf_D_DRIVE/tchesco-os-1.0-amd64.iso"
WORK_IMG="/media/sf_D_DRIVE/tchesco-work.img"
WORK_MNT="/mnt/tchesco-work"
MBR_IMG="/var/tmp/kubuntu-mbr.img"
EFI_IMG="/var/tmp/kubuntu-efi.img"
LOG="/var/log/tchesco-rebuild-v2.log"

SUPORTE_HOME="/home/suporte"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }
die() { echo "ERRO: $*" >&2; exit 1; }

mkdir -p "$(dirname "$LOG")"; touch "$LOG"
echo "" >> "$LOG"
log "=== Tchesco OS Rebuild v2 ==="

# ─── 1. Workspace no D: (30GB) ────────────────────────────────────────────────
log "[1/9] Criando workspace 30GB no D:..."
umount "$WORK_MNT" 2>/dev/null || true
rm -f "$WORK_IMG"
truncate -s 30G "$WORK_IMG"
mkfs.ext4 -F "$WORK_IMG" >> "$LOG" 2>&1
mkdir -p "$WORK_MNT"
mount -o loop "$WORK_IMG" "$WORK_MNT"
log "Workspace: $(df -h "$WORK_MNT" | tail -1 | awk '{print $2" total, "$4" livre"}')"

# ─── 2. MBR + EFI ─────────────────────────────────────────────────────────────
log "[2/9] Extraindo MBR e EFI..."
python3 - << 'PYEOF'
with open("/media/sf_D_DRIVE/Downloads/kubuntu-26.04-desktop-amd64.iso", "rb") as f:
    mbr = f.read(432)
    f.seek(9889132 * 512)
    efi = f.read(10296 * 512)
with open("/var/tmp/kubuntu-mbr.img", "wb") as f: f.write(mbr)
with open("/var/tmp/kubuntu-efi.img", "wb") as f: f.write(efi)
print(f"  MBR: {len(mbr)}b  EFI: {len(efi)//1024}KB")
PYEOF

# ─── 3. Monta ISOs ────────────────────────────────────────────────────────────
log "[3/9] Montando ISOs..."
mkdir -p /mnt/kub-iso /mnt/boot-iso
mount -o loop,ro "$KUBUNTU_ISO" /mnt/kub-iso  2>/dev/null || true
mount -o loop,ro "$BOOT_ISO"    /mnt/boot-iso 2>/dev/null || true

# ─── 4. Extrai squashfs ───────────────────────────────────────────────────────
log "[4/9] Extraindo squashfs (~5 min)..."
FS_DIR="$WORK_MNT/fs"
unsquashfs -d "$FS_DIR" /mnt/boot-iso/casper/filesystem.squashfs >> "$LOG" 2>&1
log "  squashfs: $(du -sh "$FS_DIR" | cut -f1)"

# ─── 5. Aplica correções no squashfs ──────────────────────────────────────────
log "[5/9] Aplicando correções no squashfs..."

## 5a. Remove plasma-welcome e kubuntu-welcome completamente
log "  5a. Removendo plasma-welcome..."
chroot "$FS_DIR" apt-get remove -y --purge plasma-welcome kubuntu-welcome \
    kubuntu-welcome-plasma 2>/dev/null >> "$LOG" 2>&1 || true

# Remove autostart mesmo se o pacote não existia
rm -f "$FS_DIR/etc/xdg/autostart/plasma-welcome.desktop" \
      "$FS_DIR/etc/xdg/autostart/kubuntu-welcome.desktop" \
      "$FS_DIR/etc/xdg/autostart/org.kde.plasma-welcome.desktop" 2>/dev/null || true

## 5b. Copia configs KDE reais do usuário suporte para ubuntu + skel
log "  5b. Copiando configs KDE do suporte para live user..."

mkdir -p "$FS_DIR/home/ubuntu"
mkdir -p "$FS_DIR/etc/skel"

# Lista de configs KDE críticas
KDE_ITEMS=(
    ".config/plasma-org.kde.plasma.desktop-appletsrc"
    ".config/plasmashellrc"
    ".config/plasmarc"
    ".config/kwinrc"
    ".config/kdeglobals"
    ".config/kcminputrc"
    ".config/kwinrulesrc"
    ".config/kdedefaults"
    ".config/gtk-3.0"
    ".config/gtk-4.0"
    ".config/gtkrc"
    ".config/gtkrc-2.0"
    ".config/plank"
    ".config/autostart"
    ".config/plasma-workspace"
    ".local/share/wallpapers"
    ".local/share/plasma"
    ".local/share/color-schemes"
    ".local/share/icons"
    ".themes"
)

for item in "${KDE_ITEMS[@]}"; do
    src="$SUPORTE_HOME/$item"
    if [[ -e "$src" ]]; then
        dst_dir=$(dirname "$item")
        mkdir -p "$FS_DIR/home/ubuntu/$dst_dir"
        mkdir -p "$FS_DIR/etc/skel/$dst_dir"
        cp -a "$src" "$FS_DIR/home/ubuntu/$dst_dir/" 2>/dev/null || true
        cp -a "$src" "$FS_DIR/etc/skel/$dst_dir/"    2>/dev/null || true
    fi
done

# Corrige ownership
chroot "$FS_DIR" bash -c "chown -R ubuntu:ubuntu /home/ubuntu" 2>/dev/null || true
log "  Configs KDE copiadas"

## 5c. SDDM autologin
cat > "$FS_DIR/etc/sddm.conf.d/30-tchesco-x11.conf" << 'EOF'
[Autologin]
User=ubuntu
Session=plasmax11

[X11]
MinimumVT=1
EOF

## 5d. Senha live tchesco
chroot "$FS_DIR" bash -c "echo 'ubuntu:tchesco' | chpasswd" 2>/dev/null || true

## 5e. Instala Tchesco Welcome
log "  5e. Instalando Tchesco Welcome..."
WELCOME_SRC="$(find /home /root -name "tchesco-welcome" -path "*/setup/welcome/*" 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo "")"
if [[ -n "$WELCOME_SRC" ]]; then
    mkdir -p "$FS_DIR/opt/tchesco-setup"
    cp "$WELCOME_SRC/tchesco-welcome"                   "$FS_DIR/opt/tchesco-setup/"
    cp "$WELCOME_SRC/tchesco-welcome.desktop"            "$FS_DIR/opt/tchesco-setup/"
    cp "$WELCOME_SRC/tchesco-welcome-autostart.desktop"  "$FS_DIR/opt/tchesco-setup/"
    cp "$WELCOME_SRC/install-welcome.sh"                 "$FS_DIR/opt/tchesco-setup/"

    # Monta bind mounts mínimos para apt
    mount -t proc  proc  "$FS_DIR/proc"
    mount -o bind  /dev  "$FS_DIR/dev"
    mount -t sysfs sysfs "$FS_DIR/sys"
    printf "nameserver 8.8.8.8\n" > "$FS_DIR/etc/resolv.conf"

    chroot "$FS_DIR" apt-get install -y -qq python3-pyqt6 python3-pyqt6.qtsvg >> "$LOG" 2>&1 || true
    chroot "$FS_DIR" bash /opt/tchesco-setup/install-welcome.sh >> "$LOG" 2>&1 || true

    umount "$FS_DIR/sys" "$FS_DIR/dev" "$FS_DIR/proc" 2>/dev/null || true
    log "  Welcome instalado"
else
    log "  AVISO: Welcome não encontrado"
fi

## 5f. Calamares branding
CALAMARES_CONF="$FS_DIR/etc/calamares/settings.conf"
if [[ -f "$CALAMARES_CONF" ]]; then
    sed -i 's/branding: kubuntu/branding: tchesco/g' "$CALAMARES_CONF"
    sed -i 's/branding: ubuntu/branding: tchesco/g' "$CALAMARES_CONF"
    log "  Calamares: branding tchesco aplicado"
fi

# ─── 6. Corrige Plymouth no initrd ────────────────────────────────────────────
log "[6/9] Corrigindo Plymouth no initrd..."

INITRD_SRC="/mnt/boot-iso/casper/initrd"
INITRD_WORK="$WORK_MNT/initrd-work"
mkdir -p "$INITRD_WORK"

# Ubuntu usa initrd multi-parte: microcode + initrd principal
# unmkinitramfs separa corretamente
if command -v unmkinitramfs &>/dev/null; then
    unmkinitramfs "$INITRD_SRC" "$INITRD_WORK" >> "$LOG" 2>&1
else
    # Fallback: tenta extrair direto
    cd "$INITRD_WORK"
    cat "$INITRD_SRC" | (cpio -id 2>/dev/null || true)
    cd - > /dev/null
fi

# Remove temas Plymouth WhiteSur do initrd
find "$INITRD_WORK" -name "*whitesur*" -o -name "*WhiteSur*" 2>/dev/null | while read f; do
    rm -rf "$f"
    log "  Removido: $f"
done

# Força breeze-text nos configs Plymouth dentro do initrd
find "$INITRD_WORK" -name "plymouthd.conf" 2>/dev/null | while read conf; do
    sed -i 's/^Theme=.*/Theme=breeze-text/' "$conf"
    log "  Plymouth theme -> breeze-text em $conf"
done

# Reempacota initrd
log "  Reempacotando initrd..."
INITRD_NEW="$WORK_MNT/initrd-new"

# Se unmkinitramfs criou subdiretórios, reempacota cada parte
if [[ -d "$INITRD_WORK/early" ]] || [[ -d "$INITRD_WORK/main" ]]; then
    # Multi-parte
    > "$INITRD_NEW"
    for part_dir in "$INITRD_WORK"/*/; do
        if [[ -d "$part_dir" ]]; then
            (cd "$part_dir" && find . | cpio -o -H newc 2>/dev/null | gzip -9) >> "$INITRD_NEW"
        fi
    done
else
    # Parte única
    (cd "$INITRD_WORK" && find . | cpio -o -H newc 2>/dev/null | gzip -9) > "$INITRD_NEW"
fi

log "  initrd: $(ls -lh "$INITRD_NEW" | awk '{print $5}')"

# ─── 7. Prepara ISO dir (só arquivos pequenos) ────────────────────────────────
log "[7/9] Preparando estrutura ISO..."
ISO_DIR="$WORK_MNT/iso"
mkdir -p "$ISO_DIR/casper"
rsync -a --exclude="casper/" /mnt/kub-iso/ "$ISO_DIR/" >> "$LOG" 2>&1

# Copia kernel e initrd atualizado
cp /mnt/kub-iso/casper/vmlinuz "$ISO_DIR/casper/"
cp "$INITRD_NEW" "$ISO_DIR/casper/initrd"

# GRUB labels
sed -i 's/Try or Install Kubuntu/Try or Install Tchesco OS/g' "$ISO_DIR/boot/grub/grub.cfg" 2>/dev/null || true
sed -i 's/Kubuntu (safe graphics)/Tchesco OS (safe graphics)/g' "$ISO_DIR/boot/grub/grub.cfg" 2>/dev/null || true
sed -i 's/Try or Install Kubuntu/Try or Install Tchesco OS/g' "$ISO_DIR/boot/grub/loopback.cfg" 2>/dev/null || true
sed -i 's/Kubuntu (safe graphics)/Tchesco OS (safe graphics)/g' "$ISO_DIR/boot/grub/loopback.cfg" 2>/dev/null || true

# disk/info
echo "Tchesco OS 1.0 \"Resolute Raccoon\" - Release amd64 ($(date +%Y%m%d))" \
    > "$ISO_DIR/.disk/info"

# ─── 8. Recomprime squashfs ───────────────────────────────────────────────────
log "[8/9] Recomprimindo squashfs (~15 min)..."
SQUASHFS_OUT="/media/sf_D_DRIVE/tchesco-fixed.squashfs"
rm -f "$SQUASHFS_OUT"
mksquashfs "$FS_DIR" "$SQUASHFS_OUT" -comp gzip -noappend >> "$LOG" 2>&1
log "  squashfs: $(ls -lh "$SQUASHFS_OUT" | awk '{print $5}')"

# Atualiza manifest e size
chroot "$FS_DIR" dpkg-query -W --showformat='${Package} ${Version}\n' \
    > "$ISO_DIR/casper/filesystem.manifest" 2>/dev/null || true
du -sx --block-size=1 "$FS_DIR" | cut -f1 > "$ISO_DIR/casper/filesystem.size" 2>/dev/null || true

# ─── 9. Gera ISO ──────────────────────────────────────────────────────────────
log "[9/9] Gerando ISO final..."
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
    "$ISO_DIR" \
    "casper/filesystem.squashfs=$SQUASHFS_OUT"

log "ISO gerada: $(ls -lh "$OUTPUT_ISO" | awk '{print $5}')"
log "MD5: $(md5sum "$OUTPUT_ISO" | cut -d' ' -f1)"

# ─── Verificação ──────────────────────────────────────────────────────────────
echo ""
echo "=== Verificação Final ==="
isoinfo -d -i "$OUTPUT_ISO" 2>/dev/null | grep -iE "Torito|Volume"
file "$OUTPUT_ISO"

# ─── Cleanup ──────────────────────────────────────────────────────────────────
log "Limpando workspace..."
umount /mnt/kub-iso /mnt/boot-iso 2>/dev/null || true
umount "$WORK_MNT" 2>/dev/null || true
rm -f "$WORK_IMG" "$SQUASHFS_OUT" "$MBR_IMG" "$EFI_IMG"

log "=== Rebuild v2 concluído ==="
echo ""
echo "ISO pronta: $OUTPUT_ISO"
