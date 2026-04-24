#!/usr/bin/env bash
# Módulo 05 — Pilar Office
# Fase 6 do roadmap: LibreOffice, OnlyOffice, VLC, GIMP, OBS, Spotify, Telegram, Discord, Timeshift

set -euo pipefail

LOG_FILE="/var/log/tchesco-install.log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [05-office] $*" >> "$LOG_FILE"; }
info() { echo -e "${CYAN}${BOLD}[TCHESCO]${NC} ${BLUE}$*${NC}"; log "INFO: $*"; }
ok()   { echo -e "${GREEN}${BOLD}[OK]${NC} $*"; log "OK: $*"; }
warn() { echo -e "${YELLOW}${BOLD}[AVISO]${NC} $*"; log "WARN: $*"; }
die()  { echo -e "${RED}${BOLD}[ERRO]${NC} $*" >&2; log "ERRO: $*"; exit 1; }
step() { echo ""; echo -e "${BOLD}━━━ $* ━━━${NC}"; log "STEP: $*"; }

get_real_user() {
    REAL_USER="${SUDO_USER:-}"
    [[ -z "$REAL_USER" ]] && REAL_USER=$(getent passwd | awk -F: '$3>=1000&&$3<65534{print $1;exit}')
    [[ -z "$REAL_USER" ]] && die "Usuário real não encontrado."
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    log "Usuário: $REAL_USER ($REAL_HOME)"
}

as_user() { sudo -u "$REAL_USER" env HOME="$REAL_HOME" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" "$@"; }
check_root() { [[ $EUID -eq 0 ]] || die "Execute como root: sudo $0"; }

init_log() {
    mkdir -p "$(dirname "$LOG_FILE")"; touch "$LOG_FILE"
    log "════════════════════════════════════"
    log "Iniciando módulo 05-office"
    log "════════════════════════════════════"
}

# ─── LibreOffice ──────────────────────────────────────────────────────────────

install_libreoffice() {
    step "Instalando LibreOffice"

    if dpkg -s libreoffice &>/dev/null 2>&1; then
        warn "LibreOffice já instalado"; return 0
    fi

    # Aceita EULA das fontes Microsoft (necessário para compatibilidade .docx/.xlsx)
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" \
        | debconf-set-selections

    local packages=(
        libreoffice
        libreoffice-l10n-pt-br
        libreoffice-help-pt-br
        libreoffice-qt6          # Integração visual KDE/Qt6
        ttf-mscorefonts-installer
    )

    local to_install=()
    for pkg in "${packages[@]}"; do
        dpkg -s "$pkg" &>/dev/null 2>&1 || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Instalando ${#to_install[@]} pacote(s) LibreOffice..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${to_install[@]}" >> "$LOG_FILE" 2>&1
    fi

    # libreoffice-qt6 pode não existir no 26.04 — tenta kf6 como alternativa
    if ! dpkg -s libreoffice-qt6 &>/dev/null 2>&1; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libreoffice-kf6 >> "$LOG_FILE" 2>&1 \
            || warn "Integração KDE LibreOffice não disponível — usando padrão"
    fi

    ok "LibreOffice instalado"
}

# ─── OnlyOffice ───────────────────────────────────────────────────────────────

install_onlyoffice() {
    step "Instalando OnlyOffice Desktop"

    if flatpak list --app 2>/dev/null | grep -q "org.onlyoffice.desktopeditors"; then
        warn "OnlyOffice já instalado (Flatpak)"; return 0
    fi

    info "Instalando OnlyOffice via Flatpak..."
    flatpak install -y --noninteractive flathub org.onlyoffice.desktopeditors >> "$LOG_FILE" 2>&1 \
        && ok "OnlyOffice instalado" \
        || warn "Falha ao instalar OnlyOffice — continuando"
}

# ─── Mídia ────────────────────────────────────────────────────────────────────

install_media() {
    step "Instalando players de mídia (VLC, MPV)"

    local packages=(vlc mpv)
    local to_install=()

    for pkg in "${packages[@]}"; do
        dpkg -s "$pkg" &>/dev/null 2>&1 && warn "$pkg já instalado" || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        # ubuntu-restricted-extras inclui codecs proprietários (MP3, AAC, H.264...)
        echo "ubuntu-restricted-extras ubuntu-restricted-extras/accepted-mscorefonts-eula select true" \
            | debconf-set-selections
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
            "${to_install[@]}" \
            ubuntu-restricted-extras \
            >> "$LOG_FILE" 2>&1
    fi

    ok "Players de mídia instalados"
}

# ─── Gráficos ─────────────────────────────────────────────────────────────────

install_graphics() {
    step "Instalando ferramentas gráficas (GIMP, Inkscape, Krita)"

    local packages=(gimp inkscape krita)
    local to_install=()

    for pkg in "${packages[@]}"; do
        dpkg -s "$pkg" &>/dev/null 2>&1 && warn "$pkg já instalado" || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Instalando ${#to_install[@]} ferramenta(s) gráfica(s)..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${to_install[@]}" >> "$LOG_FILE" 2>&1
    fi

    ok "Ferramentas gráficas instaladas"
}

# ─── Vídeo ────────────────────────────────────────────────────────────────────

install_video() {
    step "Instalando edição de vídeo (Kdenlive, OBS)"

    # Kdenlive via apt
    if ! dpkg -s kdenlive &>/dev/null 2>&1; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq kdenlive >> "$LOG_FILE" 2>&1 \
            && ok "Kdenlive instalado" \
            || warn "Kdenlive não disponível — pulando"
    else
        warn "Kdenlive já instalado"
    fi

    # OBS via apt (universe); se falhar, usa Flatpak
    if dpkg -s obs-studio &>/dev/null 2>&1; then
        warn "OBS já instalado"
    elif DEBIAN_FRONTEND=noninteractive apt-get install -y -qq obs-studio >> "$LOG_FILE" 2>&1; then
        ok "OBS Studio instalado (apt)"
    else
        info "OBS não encontrado no apt — instalando via Flatpak..."
        flatpak install -y --noninteractive flathub com.obsproject.Studio >> "$LOG_FILE" 2>&1 \
            && ok "OBS Studio instalado (Flatpak)" \
            || warn "Falha ao instalar OBS — continuando"
    fi
}

# ─── Comunicação + Entretenimento (Flatpak) ───────────────────────────────────

install_communication() {
    step "Instalando apps de comunicação e entretenimento"

    local app_ids=(
        "com.spotify.Client"
        "org.telegram.desktop"
        "com.discordapp.Discord"
    )
    local app_names=(
        "Spotify"
        "Telegram"
        "Discord"
    )

    for i in "${!app_ids[@]}"; do
        local app_id="${app_ids[$i]}"
        local name="${app_names[$i]}"

        if flatpak list --app 2>/dev/null | grep -q "$app_id"; then
            warn "$name já instalado"
        else
            info "Instalando $name..."
            flatpak install -y --noninteractive flathub "$app_id" >> "$LOG_FILE" 2>&1 \
                && ok "$name instalado" \
                || warn "Falha ao instalar $name — continuando"
        fi
    done
}

# ─── Impressão e Scanner ──────────────────────────────────────────────────────

install_printing() {
    step "Instalando suporte a impressão e scanner"

    local packages=(
        cups
        cups-browsed
        sane-utils
        simple-scan
        printer-driver-all
    )

    local to_install=()
    for pkg in "${packages[@]}"; do
        dpkg -s "$pkg" &>/dev/null 2>&1 || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${to_install[@]}" >> "$LOG_FILE" 2>&1
    fi

    systemctl enable cups >> "$LOG_FILE" 2>&1 || true
    usermod -aG lpadmin "$REAL_USER" >> "$LOG_FILE" 2>&1 || true

    ok "Impressão e scanner configurados"
}

# ─── Timeshift (Backup) ───────────────────────────────────────────────────────

install_timeshift() {
    step "Instalando Timeshift (backup)"

    if dpkg -s timeshift &>/dev/null 2>&1; then
        warn "Timeshift já instalado"; return 0
    fi

    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq timeshift >> "$LOG_FILE" 2>&1 \
        && ok "Timeshift instalado" \
        || warn "Timeshift não disponível nos repositórios — pulando"
}

# ─── Resumo ───────────────────────────────────────────────────────────────────

print_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║   Módulo 05-office concluído com êxito!      ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Office:${NC}      LibreOffice (pt-BR), OnlyOffice"
    echo -e "  ${BOLD}Mídia:${NC}       VLC, MPV, codecs proprietários"
    echo -e "  ${BOLD}Gráficos:${NC}    GIMP, Inkscape, Krita"
    echo -e "  ${BOLD}Vídeo:${NC}       Kdenlive, OBS Studio"
    echo -e "  ${BOLD}Comunicação:${NC} Spotify, Telegram, Discord"
    echo -e "  ${BOLD}Impressão:${NC}   CUPS, SANE, Simple Scan"
    echo -e "  ${BOLD}Backup:${NC}      Timeshift"
    echo ""
    log "Módulo 05-office finalizado com sucesso"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║   Tchesco OS — Módulo 05: Office              ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    init_log
    check_root
    get_real_user
    install_libreoffice
    install_onlyoffice
    install_media
    install_graphics
    install_video
    install_communication
    install_printing
    install_timeshift
    print_summary
}

main "$@"
