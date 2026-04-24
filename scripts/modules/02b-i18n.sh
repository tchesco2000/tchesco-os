#!/usr/bin/env bash
# Módulo 02b — Internacionalização (i18n)
# Fase 3.5 do roadmap: multi-idioma, fontes, fcitx5, layouts de teclado

set -euo pipefail

# ─── Constantes ───────────────────────────────────────────────────────────────

LOG_FILE="/var/log/tchesco-install.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Helpers ──────────────────────────────────────────────────────────────────

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [02b-i18n] $*" >> "$LOG_FILE"; }
info() { echo -e "${CYAN}${BOLD}[TCHESCO]${NC} ${BLUE}$*${NC}"; log "INFO: $*"; }
ok()   { echo -e "${GREEN}${BOLD}[OK]${NC} $*"; log "OK: $*"; }
warn() { echo -e "${YELLOW}${BOLD}[AVISO]${NC} $*"; log "WARN: $*"; }
die()  { echo -e "${RED}${BOLD}[ERRO]${NC} $*" >&2; log "ERRO: $*"; exit 1; }
step() { echo ""; echo -e "${BOLD}━━━ $* ━━━${NC}"; log "STEP: $*"; }

# ─── Usuário real ─────────────────────────────────────────────────────────────

get_real_user() {
    REAL_USER="${SUDO_USER:-}"
    if [[ -z "$REAL_USER" ]]; then
        REAL_USER=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1; exit}')
    fi
    [[ -z "$REAL_USER" ]] && die "Não foi possível identificar o usuário real."
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    log "Usuário real: $REAL_USER ($REAL_HOME)"
}

as_user() {
    sudo -u "$REAL_USER" env HOME="$REAL_HOME" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" "$@"
}

check_root() {
    [[ $EUID -eq 0 ]] || die "Execute como root: sudo $0"
}

init_log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    log "════════════════════════════════════"
    log "Iniciando módulo 02b-i18n"
    log "════════════════════════════════════"
}

# ─── Language packs ───────────────────────────────────────────────────────────

install_language_packs() {
    step "Instalando pacotes de idioma"

    export DEBIAN_FRONTEND=noninteractive

    # Idiomas ocidentais + os mais falados do mundo
    local langs=(
        pt pt-base
        en en-base
        es es-base
        fr fr-base
        de de-base
        it it-base
        ja ja-base
        zh-hans zh-hans-base
        ko ko-base
        ru ru-base
        ar ar-base
    )

    local to_install=()
    for lang in "${langs[@]}"; do
        local pkg="language-pack-${lang}"
        dpkg -s "$pkg" &>/dev/null 2>&1 || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Instalando ${#to_install[@]} language packs..."
        apt-get install -y -qq "${to_install[@]}" >> "$LOG_FILE" 2>&1
    else
        warn "Language packs já instalados"
    fi

    # Gera locales necessários
    info "Gerando locales..."
    local locales_to_gen=(
        "pt_BR.UTF-8"
        "en_US.UTF-8"
        "es_ES.UTF-8"
        "fr_FR.UTF-8"
        "de_DE.UTF-8"
        "ja_JP.UTF-8"
        "zh_CN.UTF-8"
        "ko_KR.UTF-8"
    )

    for loc in "${locales_to_gen[@]}"; do
        locale -a 2>/dev/null | grep -q "${loc/UTF-8/utf8}" || locale-gen "$loc" >> "$LOG_FILE" 2>&1
    done

    # Garante pt_BR como padrão
    update-locale LANG=pt_BR.UTF-8 LC_ALL=pt_BR.UTF-8 >> "$LOG_FILE" 2>&1

    ok "Language packs instalados — padrão: pt_BR.UTF-8"
}

# ─── Fontes adicionais ────────────────────────────────────────────────────────

install_fonts() {
    step "Instalando fontes adicionais"

    local fonts=(
        fonts-jetbrains-mono
        fonts-inter
        fonts-liberation2
        fonts-open-sans
        fonts-roboto
    )

    local to_install=()
    for pkg in "${fonts[@]}"; do
        dpkg -s "$pkg" &>/dev/null 2>&1 || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Instalando: ${to_install[*]}"
        apt-get install -y -qq "${to_install[@]}" >> "$LOG_FILE" 2>&1
    else
        warn "Fontes já instaladas"
    fi

    # Atualiza cache de fontes
    fc-cache -f >> "$LOG_FILE" 2>&1
    ok "Fontes instaladas e cache atualizado"
}

# ─── fcitx5 (input method para idiomas asiáticos) ─────────────────────────────

install_fcitx5() {
    step "Instalando fcitx5 (input method)"

    local packages=(
        fcitx5                    # Framework principal
        fcitx5-mozc               # Japonês
        fcitx5-chinese-addons     # Chinês (Pinyin, Cangjie, etc)
        fcitx5-hangul             # Coreano
        fcitx5-gtk                # Integração GTK
        fcitx5-qt                 # Integração Qt/KDE
        fcitx5-configtool         # Interface gráfica de configuração
    )

    local to_install=()
    for pkg in "${packages[@]}"; do
        dpkg -s "$pkg" &>/dev/null 2>&1 || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Instalando: ${to_install[*]}"
        apt-get install -y -qq "${to_install[@]}" >> "$LOG_FILE" 2>&1
    else
        warn "fcitx5 já instalado"
        return 0
    fi

    ok "fcitx5 instalado com suporte a JP/CN/KR"
}

# ─── Configuração do fcitx5 ───────────────────────────────────────────────────

configure_fcitx5() {
    step "Configurando fcitx5 como input method padrão"

    # Variáveis de ambiente para Qt e GTK usarem fcitx5
    local env_file="$REAL_HOME/.config/environment.d/fcitx5.conf"
    as_user mkdir -p "$(dirname "$env_file")"

    cat > "$env_file" << 'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
INPUT_METHOD=fcitx
GLFW_IM_MODULE=ibus
EOF
    chown "$REAL_USER:$REAL_USER" "$env_file"

    # Autostart do fcitx5 na sessão KDE
    local autostart_dir="$REAL_HOME/.config/autostart"
    mkdir -p "$autostart_dir"
    cat > "$autostart_dir/fcitx5.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Fcitx5
GenericName=Input Method
Exec=fcitx5
Icon=fcitx5
NoDisplay=false
StartupNotify=false
X-GNOME-Autostart-Phase=Applications
X-GNOME-AutoRestart=false
X-GNOME-Autostart-Notify=false
X-KDE-autostart-after=panel
EOF
    chown "$REAL_USER:$REAL_USER" "$autostart_dir/fcitx5.desktop"

    # Configuração básica do fcitx5 — adiciona teclado BR como entrada padrão
    local fcitx_config_dir="$REAL_HOME/.config/fcitx5"
    as_user mkdir -p "$fcitx_config_dir"

    cat > "$fcitx_config_dir/config" << 'EOF'
[Hotkey]
# Alterna entre idiomas: Ctrl+Space
TriggerKeys=Control+space
EnumerateForwardKeys=
EnumerateBackwardKeys=
EnumerateSkipFirst=False

[Behavior]
ActiveByDefault=False
ShareInputState=No
PreeditEnabledByDefault=True
ShowInputMethodInformation=True
ShowInputMethodInformationWhenFocusIn=False
CompactInputMethodInformation=True
ShowFirstInputMethodInformation=True
EOF
    chown -R "$REAL_USER:$REAL_USER" "$fcitx_config_dir"

    ok "fcitx5 configurado — Ctrl+Space para alternar idiomas"
}

# ─── Corretor ortográfico ─────────────────────────────────────────────────────

install_spellcheck() {
    step "Instalando corretores ortográficos"

    local packages=(
        hunspell-pt-br
        hunspell-en-us
        hunspell-es
        hunspell-fr
        hunspell-de-de
        myspell-pt-br
    )

    local to_install=()
    for pkg in "${packages[@]}"; do
        dpkg -s "$pkg" &>/dev/null 2>&1 || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Instalando: ${to_install[*]}"
        apt-get install -y -qq "${to_install[@]}" >> "$LOG_FILE" 2>&1
    else
        warn "Corretores já instalados"
    fi

    ok "Corretores ortográficos instalados"
}

print_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║   Módulo 02b-i18n concluído com êxito!     ║${NC}"
    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Idiomas:${NC}    PT-BR (padrão) + EN, ES, FR, DE, JA, ZH, KO, RU, AR"
    echo -e "  ${BOLD}Input:${NC}      fcitx5 — Ctrl+Space para alternar"
    echo -e "  ${BOLD}Japonês:${NC}    Mozc (fcitx5-mozc)"
    echo -e "  ${BOLD}Chinês:${NC}     Pinyin (fcitx5-chinese-addons)"
    echo -e "  ${BOLD}Coreano:${NC}    Hangul (fcitx5-hangul)"
    echo -e "  ${BOLD}Fontes:${NC}     JetBrains Mono, Inter, Roboto, Open Sans"
    echo ""
    echo -e "  ${YELLOW}Reinicie a sessão para ativar fcitx5.${NC}"
    echo ""
    log "Módulo 02b-i18n finalizado com sucesso"
}

# ─── Execução ─────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║   Tchesco OS — Módulo 02b: Internacionalização║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    init_log
    check_root
    get_real_user
    install_language_packs
    install_fonts
    install_fcitx5
    configure_fcitx5
    install_spellcheck
    print_summary
}

main "$@"
