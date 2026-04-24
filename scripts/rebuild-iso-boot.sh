#!/usr/bin/env bash
# Reconstrói a ISO Tchesco OS com boot EFI+BIOS correto
set -euo pipefail

KUBUNTU_ISO="/media/sf_D_DRIVE/Downloads/kubuntu-26.04-desktop-amd64.iso"
BOOT_ISO="/media/sf_D_DRIVE/tchesco-os-1.0-BOOT.iso"
OUTPUT_ISO="/media/sf_D_DRIVE/tchesco-os-1.0-FINAL.iso"
BUILD_DIR="/var/tmp/iso-build"
MBR_IMG="/var/tmp/kubuntu-mbr.img"
EFI_IMG="/var/tmp/kubuntu-efi.img"

echo "[1/6] Limpeza..."
rm -f /tmp/tchesco.squashfs /tmp/tchesco.manifest /tmp/tchesco.size /tmp/tchesco-md5.txt
rm -f /var/tmp/kubuntu-mbr.img /var/tmp/kubuntu-efi.img
rm -rf "$BUILD_DIR"
df -h / | tail -1

echo "[2/6] Extraindo MBR (432 bytes) e EFI (5MB) via Python..."
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

echo "[3/6] Montando ISOs..."
mkdir -p /mnt/kub-iso /mnt/boot-iso
mount -o loop,ro "$KUBUNTU_ISO" /mnt/kub-iso  || true
mount -o loop,ro "$BOOT_ISO"    /mnt/boot-iso || true
ls -lh /mnt/boot-iso/casper/filesystem.squashfs

echo "[4/6] Preparando diretório de build (rsync sem squashfs ~500MB)..."
mkdir -p "$BUILD_DIR/casper"
rsync -a --exclude="casper/filesystem.squashfs" /mnt/kub-iso/ "$BUILD_DIR/"
echo "rsync: $(du -sh "$BUILD_DIR" | cut -f1)"

echo "[5/6] Copiando squashfs Tchesco (5.9GB)..."
cp /mnt/boot-iso/casper/filesystem.squashfs "$BUILD_DIR/casper/filesystem.squashfs"
echo "squashfs: $(ls -lh "$BUILD_DIR/casper/filesystem.squashfs" | awk '{print $5}')"
df -h / | tail -1

echo "[6/6] Gerando ISO bootável com xorriso..."
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
    "$BUILD_DIR"

echo ""
echo "=== Verificação ==="
isoinfo -d -i "$OUTPUT_ISO" 2>/dev/null | grep -iE "Torito|Joliet|Volume"
file "$OUTPUT_ISO"
ls -lh "$OUTPUT_ISO"
md5sum "$OUTPUT_ISO"

echo ""
echo "=== Cleanup ==="
umount /mnt/kub-iso /mnt/boot-iso 2>/dev/null || true
rm -rf "$BUILD_DIR" "$MBR_IMG" "$EFI_IMG"
echo "Feito!"
