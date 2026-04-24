#!/usr/bin/env bash
# Tchesco OS — Build da ISO
# Fase 10: gera tchesco-os-1.0-amd64.iso a partir da ISO Kubuntu 26.04
#
# Uso: sudo bash scripts/build-iso.sh <kubuntu-26.04.iso> [saida.iso] [gzip|xz]
#
# Pré-requisitos:
#   - ~12GB livres em disco
#   - ISO Kubuntu 26.04 desktop amd64
#   - Conexão com internet (para instalar ferramentas de build)

set -euo pipefail

# ─── Argumentos ───────────────────────────────────────────────────────────────

ORIG_ISO="${1:-}"
OUTPUT_ISO="${2:-/tmp/tchesco-os-1.0-amd64.iso}"
COMPRESSION="${3:-gzip}"   # gzip = rápido (~30min), xz = menor (~90min)

[[ -z "$ORIG_ISO" ]] && { echo "Uso: sudo bash $0 <kubuntu.iso> [saida.iso] [gzip|xz]"; exit 1; }
[[ -f "$ORIG_ISO" ]]  || { echo "ERRO: ISO não encontrada: $ORIG_ISO"; exit 1; }
[[ $EUID -eq 0 ]]     || { echo "ERRO: Execute como root: sudo bash $0 ..."; exit 1; }

# ─── Configuração ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WORK_DIR="/tmp/tchesco-iso-build"
ISO_DIR="$WORK_DIR/iso"
SQUASHFS_DIR="$WORK_DIR/squashfs"
LOG_FILE="/var/log/tchesco-build-iso.log"
START_TIME=$(date +%s)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
info() { echo -e "${CYAN}${BOLD}[TCHESCO]${NC} $*"; log "INFO: $*"; }
ok()   { echo -e "${GREEN}${BOLD}[OK]${NC} $*"; log "OK: $*"; }
warn() { echo -e "${YELLOW}${BOLD}[AVISO]${NC} $*"; log "WARN: $*"; }
die()  { echo -e "${RED}${BOLD}[ERRO]${NC} $*" >&2; log "ERRO: $*"; teardown_chroot 2>/dev/null || true; exit 1; }
step() { echo ""; echo -e "${BOLD}━━━ $* ━━━${NC}"; log "--- $* ---"; }

elapsed_since() {
    local s=$(( $(date +%s) - $1 ))
    printf "%dm %02ds" $(( s / 60 )) $(( s % 60 ))
}

# ─── Verificações iniciais ─────────────────────────────────────────────────────

check_requirements() {
    step "Verificando requisitos"

    # Espaço livre
    local free_gb; free_gb=$(df -BG / | awk 'NR==2{print $4}' | tr -d G)
    info "Espaço livre: ${free_gb}GB (mínimo 12GB)"
    [[ "$free_gb" -lt 10 ]] && die "Espaço insuficiente: ${free_gb}GB < 10GB"

    # ISO
    local iso_size; iso_size=$(du -h "$ORIG_ISO" | cut -f1)
    info "ISO origem: $(basename "$ORIG_ISO") ($iso_size)"

    # Destino de saída
    local out_dir; out_dir=$(dirname "$OUTPUT_ISO")
    mkdir -p "$out_dir"
    info "ISO saída: $OUTPUT_ISO"
    info "Compressão: $COMPRESSION"

    ok "Requisitos OK"
}

# ─── Ferramentas de build ─────────────────────────────────────────────────────

install_build_tools() {
    step "Instalando ferramentas de build"

    local tools=(xorriso squashfs-tools genisoimage librsvg2-bin python3-pil grub-pc-bin)
    local to_install=()

    for t in "${tools[@]}"; do
        dpkg -s "$t" &>/dev/null 2>&1 || to_install+=("$t")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        apt-get update -qq >> "$LOG_FILE" 2>&1
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${to_install[@]}" >> "$LOG_FILE" 2>&1
    fi

    # Libera cache apt para ganhar espaço antes do build
    info "Liberando cache apt..."
    apt-get clean >> "$LOG_FILE" 2>&1
    ok "Ferramentas prontas (cache apt limpo)"
}

# ─── Extração da ISO ──────────────────────────────────────────────────────────

extract_iso() {
    step "Extraindo ISO original"

    rm -rf "$WORK_DIR"
    mkdir -p "$ISO_DIR" "$SQUASHFS_DIR"

    info "Extraindo arquivos da ISO (pode demorar)..."
    xorriso -osirrox on -indev "$ORIG_ISO" -extract / "$ISO_DIR" >> "$LOG_FILE" 2>&1
    chmod -R u+w "$ISO_DIR"

    local squashfs="$ISO_DIR/casper/filesystem.squashfs"
    [[ -f "$squashfs" ]] || die "filesystem.squashfs não encontrado em $ISO_DIR/casper/"

    info "Extraindo filesystem (squashfs → ~6GB, aguarde)..."
    unsquashfs -d "$SQUASHFS_DIR" "$squashfs" >> "$LOG_FILE" 2>&1

    # Remove squashfs original do ISO_DIR (será regenerado)
    rm -f "$squashfs"

    ok "ISO extraída — $(du -sh "$SQUASHFS_DIR" | cut -f1) descomprimido"
}

# ─── Configuração do chroot ───────────────────────────────────────────────────

setup_chroot() {
    step "Preparando chroot"

    # Bind mounts necessários
    mount -t proc  proc            "$SQUASHFS_DIR/proc"
    mount -t sysfs sysfs           "$SQUASHFS_DIR/sys"
    mount -o bind  /dev            "$SQUASHFS_DIR/dev"
    mount -o bind  /dev/pts        "$SQUASHFS_DIR/dev/pts"
    mount -o bind  /run            "$SQUASHFS_DIR/run"

    # Rede no chroot
    cp /etc/resolv.conf "$SQUASHFS_DIR/etc/resolv.conf"

    # Cria usuário live se não existir (Kubuntu usa 'ubuntu')
    if ! chroot "$SQUASHFS_DIR" id ubuntu &>/dev/null 2>&1; then
        chroot "$SQUASHFS_DIR" useradd -m -s /bin/bash -G sudo ubuntu >> "$LOG_FILE" 2>&1 || true
    fi

    # XDG_RUNTIME_DIR para as_user() dos scripts
    mkdir -p "$SQUASHFS_DIR/run/user/1000"
    chroot "$SQUASHFS_DIR" chown ubuntu:ubuntu /run/user/1000 >> "$LOG_FILE" 2>&1 || true

    ok "Chroot configurado"
}

teardown_chroot() {
    # Desmonta bind mounts (ordem inversa, com || true para não falhar se já desmontado)
    umount "$SQUASHFS_DIR/run"      2>/dev/null || true
    umount "$SQUASHFS_DIR/dev/pts"  2>/dev/null || true
    umount "$SQUASHFS_DIR/dev"      2>/dev/null || true
    umount "$SQUASHFS_DIR/sys"      2>/dev/null || true
    umount "$SQUASHFS_DIR/proc"     2>/dev/null || true
    log "Chroot desmontado"
}

# ─── Execução dos scripts no chroot ──────────────────────────────────────────

run_install_scripts() {
    step "Executando scripts Tchesco no chroot"

    # Copia scripts para dentro do chroot
    mkdir -p "$SQUASHFS_DIR/opt/tchesco-install"
    cp -r "$SCRIPT_DIR/modules" "$SQUASHFS_DIR/opt/tchesco-install/"

    local modules=(
        "01-base.sh"
        "02-theme.sh"
        "02b-i18n.sh"
        "03-dev.sh"
        "04-gaming.sh"
        "05-office.sh"
        "06-wine.sh"
        "07-identity.sh"
    )

    for module in "${modules[@]}"; do
        local mod_path="/opt/tchesco-install/modules/$module"
        info "Chroot: $module..."
        # SUDO_USER=ubuntu faz as_user() identificar o usuário correto
        if SUDO_USER=ubuntu chroot "$SQUASHFS_DIR" bash "$mod_path" >> "$LOG_FILE" 2>&1; then
            ok "$module OK"
        else
            warn "$module terminou com erro — continuando (verifique $LOG_FILE)"
        fi
    done

    # Copia configurações do usuário ubuntu para /etc/skel
    # (será aplicado a novos usuários após a instalação)
    info "Copiando configurações para /etc/skel..."
    cp -a "$SQUASHFS_DIR/home/ubuntu/." "$SQUASHFS_DIR/etc/skel/" 2>/dev/null || true

    # Remove scripts temporários
    rm -rf "$SQUASHFS_DIR/opt/tchesco-install"

    ok "Scripts executados no chroot"
}

# ─── Calamares — branding ─────────────────────────────────────────────────────

configure_calamares() {
    step "Configurando Calamares (branding Tchesco)"

    local brand_src="$PROJECT_DIR/setup/calamares/branding/tchesco"
    local brand_dst="$SQUASHFS_DIR/usr/share/calamares/branding/tchesco"

    if [[ ! -d "$brand_src" ]]; then
        warn "Branding não encontrado em $brand_src — pulando"; return 0
    fi

    mkdir -p "$brand_dst"
    cp "$brand_src/branding.desc" "$brand_dst/"
    cp "$brand_src/show.qml"      "$brand_dst/"

    # Gera logo.png a partir do SVG
    local svg="$PROJECT_DIR/tchesco-logo-pack/tchesco-os/assets/logo/tchesco-icon-kde.svg"
    if [[ -f "$svg" ]] && command -v rsvg-convert &>/dev/null; then
        rsvg-convert -w 200 -h 200 "$svg" -o "$brand_dst/logo.png" 2>/dev/null \
            && info "logo.png gerado" \
            || warn "Falha ao converter SVG — logo ausente"
    fi

    # Gera welcome.png — fundo escuro com nome do OS via Python/PIL
    python3 - << PYEOF
from PIL import Image, ImageDraw, ImageFont
img = Image.new("RGB", (1280, 720), color=(14, 17, 23))
draw = ImageDraw.Draw(img)
# Degradê simples de fundo
for y in range(720):
    r = int(14 + (30 - 14) * y / 720)
    g = int(17 + (40 - 17) * y / 720)
    b = int(23 + (80 - 23) * y / 720)
    draw.line([(0, y), (1280, y)], fill=(r, g, b))
# Texto centralizado
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", 72)
    font_sub = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf", 32)
except:
    font = ImageFont.load_default()
    font_sub = font
draw.text((640, 300), "Tchesco OS", fill=(255, 255, 255), font=font, anchor="mm")
draw.text((640, 390), "Versão 1.0 · baseado em Kubuntu 26.04 LTS", fill=(180, 180, 180), font=font_sub, anchor="mm")
img.save("$brand_dst/welcome.png")
PYEOF
    [[ -f "$brand_dst/welcome.png" ]] && info "welcome.png gerado" || warn "Falha ao gerar welcome.png"

    # Atualiza settings.conf do Calamares para usar nosso branding
    local calamares_conf="$SQUASHFS_DIR/etc/calamares/settings.conf"
    if [[ -f "$calamares_conf" ]]; then
        sed -i 's|branding: kubuntu|branding: tchesco|g' "$calamares_conf"
        sed -i 's|branding: ubuntu|branding: tchesco|g' "$calamares_conf"
        ok "Calamares settings.conf atualizado para branding 'tchesco'"
    else
        warn "settings.conf não encontrado — branding pode não ser aplicado"
    fi

    ok "Calamares configurado"
}

# ─── Limpeza do chroot ────────────────────────────────────────────────────────

cleanup_squashfs() {
    step "Limpando squashfs antes do repack"

    chroot "$SQUASHFS_DIR" apt-get clean >> "$LOG_FILE" 2>&1 || true
    chroot "$SQUASHFS_DIR" apt-get autoremove -y -qq >> "$LOG_FILE" 2>&1 || true

    rm -f "$SQUASHFS_DIR/etc/resolv.conf"
    rm -f "$SQUASHFS_DIR/root/.bash_history"
    rm -rf "$SQUASHFS_DIR/tmp/"*
    rm -rf "$SQUASHFS_DIR/var/crash/"*

    ok "Squashfs limpo"
}

# ─── Repack do squashfs ───────────────────────────────────────────────────────

repack_squashfs() {
    step "Recomprimindo squashfs ($COMPRESSION)"

    local new_squashfs="$ISO_DIR/casper/filesystem.squashfs"

    info "mksquashfs em andamento (pode demorar bastante)..."
    mksquashfs "$SQUASHFS_DIR" "$new_squashfs" \
        -comp "$COMPRESSION" \
        -noappend \
        -no-progress \
        >> "$LOG_FILE" 2>&1

    # Atualiza manifest e size
    chroot "$SQUASHFS_DIR" dpkg-query -W --showformat='${Package} ${Version}\n' \
        > "$ISO_DIR/casper/filesystem.manifest" 2>/dev/null || true

    du -sx --block-size=1 "$SQUASHFS_DIR" | cut -f1 \
        > "$ISO_DIR/casper/filesystem.size" 2>/dev/null || true

    # Atualiza MD5 sums
    info "Atualizando checksums..."
    cd "$ISO_DIR"
    find . -type f -not -name "md5sum.txt" -print0 | \
        xargs -0 md5sum 2>/dev/null > md5sum.txt || true
    cd - > /dev/null

    ok "Squashfs recomprimido: $(du -h "$new_squashfs" | cut -f1)"
}

# ─── Geração da ISO ───────────────────────────────────────────────────────────

generate_iso() {
    step "Gerando ISO final"

    info "Lendo parâmetros de boot da ISO original..."
    local boot_params
    boot_params=$(xorriso -indev "$ORIG_ISO" -report_system_area as_mkisofs 2>/dev/null | head -1 || echo "")

    if [[ -z "$boot_params" ]]; then
        warn "Não foi possível ler parâmetros de boot — usando padrão EFI+BIOS"
        boot_params="-isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
            -eltorito-boot boot/grub/i386-pc/eltorito.img \
            -no-emul-boot -boot-load-size 4 -boot-info-table \
            --grub2-boot-info \
            -eltorito-alt-boot -e EFI/boot/bootx64.efi -no-emul-boot"
    fi

    info "Gerando ISO: $(basename "$OUTPUT_ISO")..."
    # shellcheck disable=SC2086
    xorriso -as mkisofs \
        $boot_params \
        -volid "TCHESCO_OS_1_0" \
        -volset "Tchesco OS 1.0" \
        -iso-level 3 \
        -full-iso9660-filenames \
        -output "$OUTPUT_ISO" \
        "$ISO_DIR" \
        >> "$LOG_FILE" 2>&1

    ok "ISO gerada: $(du -h "$OUTPUT_ISO" | cut -f1)"
}

# ─── Resumo ───────────────────────────────────────────────────────────────────

print_summary() {
    local total; total=$(elapsed_since "$START_TIME")
    local iso_size; iso_size=$(du -h "$OUTPUT_ISO" 2>/dev/null | cut -f1 || echo "—")
    local iso_md5; iso_md5=$(md5sum "$OUTPUT_ISO" 2>/dev/null | cut -d' ' -f1 || echo "—")

    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║       Tchesco OS — ISO gerada com sucesso!       ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}ISO:${NC}         $OUTPUT_ISO"
    echo -e "  ${BOLD}Tamanho:${NC}     $iso_size"
    echo -e "  ${BOLD}MD5:${NC}         $iso_md5"
    echo -e "  ${BOLD}Compressão:${NC}  $COMPRESSION"
    echo -e "  ${BOLD}Tempo total:${NC} $total"
    echo -e "  ${BOLD}Log:${NC}         $LOG_FILE"
    echo ""
    echo -e "  ${YELLOW}Teste em VM:${NC} importe a ISO no VirtualBox e instale em VM limpa."
    echo ""
    log "Build concluído. ISO: $OUTPUT_ISO ($iso_size) — $total"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    mkdir -p "$(dirname "$LOG_FILE")"; touch "$LOG_FILE"

    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║     Tchesco OS — Build ISO v1.0                  ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    check_requirements
    install_build_tools
    extract_iso
    setup_chroot
    run_install_scripts
    configure_calamares
    cleanup_squashfs
    teardown_chroot
    repack_squashfs
    generate_iso

    # Libera espaço do workspace
    info "Removendo workspace temporário..."
    rm -rf "$WORK_DIR"

    print_summary
}

main "$@"
