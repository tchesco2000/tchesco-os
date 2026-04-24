#!/usr/bin/env bash
# Módulo 02 — Tema visual macOS (WhiteSur + Plank)
# Fase 3 do roadmap: tema GTK, KDE Plasma 6, ícones, cursores, dock e Plymouth
#
# NOTA Latte Dock: abandonado, sem suporte para Plasma 6.
# Alternativa: Plank dock (GTK, leve, estável no Plasma 6).

set -euo pipefail

# ─── Constantes ───────────────────────────────────────────────────────────────

LOG_FILE="/var/log/tchesco-install.log"
# BUILD_DIR fica no home do usuário real para que os clones sejam de sua propriedade
# e o install.sh possa escrever nos arquivos sem precisar de chown posterior
BUILD_DIR=""  # definido em get_real_user() após identificar REAL_HOME

WHITESUR_GTK="https://github.com/vinceliuice/WhiteSur-gtk-theme.git"
WHITESUR_KDE="https://github.com/vinceliuice/WhiteSur-kde.git"
WHITESUR_ICONS="https://github.com/vinceliuice/WhiteSur-icon-theme.git"
WHITESUR_CURSORS="https://github.com/vinceliuice/WhiteSur-cursors.git"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Helpers ──────────────────────────────────────────────────────────────────

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [02-theme] $*" >> "$LOG_FILE"
}

info() {
    echo -e "${CYAN}${BOLD}[TCHESCO]${NC} ${BLUE}$*${NC}"
    log "INFO: $*"
}

ok() {
    echo -e "${GREEN}${BOLD}[OK]${NC} $*"
    log "OK: $*"
}

warn() {
    echo -e "${YELLOW}${BOLD}[AVISO]${NC} $*"
    log "WARN: $*"
}

die() {
    echo -e "${RED}${BOLD}[ERRO]${NC} $*" >&2
    log "ERRO: $*"
    exit 1
}

step() {
    echo ""
    echo -e "${BOLD}━━━ $* ━━━${NC}"
    log "STEP: $*"
}

# ─── Usuário real (quem rodou sudo) ──────────────────────────────────────────

get_real_user() {
    REAL_USER="${SUDO_USER:-}"
    if [[ -z "$REAL_USER" ]]; then
        # Fallback: primeiro usuário com UID >= 1000
        REAL_USER=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1; exit}')
    fi
    [[ -z "$REAL_USER" ]] && die "Não foi possível identificar o usuário real. Execute via sudo."
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    [[ -z "$REAL_HOME" ]] && die "Não foi possível identificar o home do usuário $REAL_USER."
    BUILD_DIR="$REAL_HOME/tchesco-theme-build"
    log "Usuário real: $REAL_USER ($REAL_HOME)"
}

# Roda um comando como o usuário real
as_user() {
    sudo -u "$REAL_USER" env HOME="$REAL_HOME" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" "$@"
}

# ─── Verificações ─────────────────────────────────────────────────────────────

check_root() {
    [[ $EUID -eq 0 ]] || die "Execute como root: sudo $0"
}

check_internet() {
    info "Verificando conexão com a internet..."
    ping -c 1 -W 5 github.com &>/dev/null || die "Sem acesso ao GitHub. Verifique sua rede."
    ok "Conexão OK"
}

# ─── Dependências de sistema ──────────────────────────────────────────────────

install_deps() {
    step "Instalando dependências do tema"

    local packages=(
        git
        plank               # Dock estilo macOS (substituto do Latte no Plasma 6)
        qt6-style-kvantum   # Engine de temas Qt para widgets mais fiéis ao macOS
        sassc               # Compilador SCSS (necessário para WhiteSur GTK)
        libglib2.0-dev-bin  # glib-compile-schemas (WhiteSur GTK)
        libgtk-4-dev        # Headers GTK4
        gnome-themes-extra  # Temas extras GTK
        gtk2-engines-murrine
        gtk2-engines-pixbuf
    )

    local to_install=()
    for pkg in "${packages[@]}"; do
        dpkg -s "$pkg" &>/dev/null 2>&1 || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Instalando: ${to_install[*]}"
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${to_install[@]}" >> "$LOG_FILE" 2>&1
    fi

    ok "Dependências instaladas"
}

# ─── Clone dos repositórios WhiteSur ─────────────────────────────────────────

clone_repos() {
    step "Clonando repositórios WhiteSur"

    # Remove build anterior e recria como usuário real (evita problema de permissão)
    rm -rf "$BUILD_DIR"
    as_user mkdir -p "$BUILD_DIR"

    local repos=(
        "whitesur-gtk|$WHITESUR_GTK"
        "whitesur-kde|$WHITESUR_KDE"
        "whitesur-icons|$WHITESUR_ICONS"
        "whitesur-cursors|$WHITESUR_CURSORS"
    )

    for entry in "${repos[@]}"; do
        local name="${entry%%|*}"
        local url="${entry##*|}"
        info "Clonando $name..."
        as_user git clone --depth=1 -q "$url" "$BUILD_DIR/$name" >> "$LOG_FILE" 2>&1
        ok "$name clonado"
    done
}

# ─── Instalação dos temas ─────────────────────────────────────────────────────

install_gtk_theme() {
    step "Instalando tema GTK WhiteSur"

    # Instala para o usuário (~/.themes) + libadwaita GTK4
    info "Instalando WhiteSur GTK (variante Light + Dark)..."
    as_user bash "$BUILD_DIR/whitesur-gtk/install.sh" \
        --dest "$REAL_HOME/.themes" \
        --name WhiteSur \
        -c light \
        -c dark \
        -o solid \
        -l \
        >> "$LOG_FILE" 2>&1

    ok "Tema GTK instalado em ~/.themes"
}

install_kde_theme() {
    step "Instalando tema KDE WhiteSur"

    info "Instalando WhiteSur para KDE Plasma 6..."
    as_user bash "$BUILD_DIR/whitesur-kde/install.sh" >> "$LOG_FILE" 2>&1

    ok "Tema KDE instalado"
}

install_icons() {
    step "Instalando ícones WhiteSur"

    info "Instalando WhiteSur icons..."
    as_user bash "$BUILD_DIR/whitesur-icons/install.sh" \
        --dest "$REAL_HOME/.local/share/icons" \
        >> "$LOG_FILE" 2>&1

    ok "Ícones instalados em ~/.local/share/icons"
}

install_cursors() {
    step "Instalando cursores WhiteSur"

    info "Instalando WhiteSur cursors..."

    # O script de cursores instala em ~/.local/share/icons
    as_user bash "$BUILD_DIR/whitesur-cursors/install.sh" >> "$LOG_FILE" 2>&1

    ok "Cursores instalados"
}

install_plymouth() {
    step "Configurando Plymouth (boot splash)"

    local plymouth_src="$BUILD_DIR/whitesur-kde/plymouth/WhiteSur"

    if [[ -d "$plymouth_src" ]]; then
        info "Instalando tema Plymouth WhiteSur..."
        cp -r "$plymouth_src" /usr/share/plymouth/themes/ >> "$LOG_FILE" 2>&1

        update-alternatives --install \
            /usr/share/plymouth/themes/default.plymouth \
            default.plymouth \
            /usr/share/plymouth/themes/WhiteSur/WhiteSur.plymouth \
            100 >> "$LOG_FILE" 2>&1

        update-alternatives --set \
            default.plymouth \
            /usr/share/plymouth/themes/WhiteSur/WhiteSur.plymouth >> "$LOG_FILE" 2>&1

        update-initramfs -u >> "$LOG_FILE" 2>&1
        ok "Plymouth configurado com tema WhiteSur"
    else
        warn "Tema Plymouth não encontrado no repositório — pulando"
        log "Plymouth: diretório $plymouth_src não existe"
    fi
}

# ─── Configuração KDE Plasma 6 ────────────────────────────────────────────────

apply_kde_config() {
    step "Aplicando configurações KDE Plasma 6"

    info "Configurando tema global..."

    # Widget style (Kvantum para widgets Qt com visual macOS)
    as_user kwriteconfig6 --file kdeglobals \
        --group KDE --key widgetStyle "kvantum"

    # Tema de cores
    as_user kwriteconfig6 --file kdeglobals \
        --group General --key ColorScheme "WhiteSur"

    # Ícones
    as_user kwriteconfig6 --file kdeglobals \
        --group Icons --key Theme "WhiteSur"

    # Cursor
    as_user kwriteconfig6 --file kdeglobals \
        --group Mouse --key cursorTheme "WhiteSur-cursors"

    # Tema de janelas KWin
    as_user kwriteconfig6 --file kwinrc \
        --group org.kde.kdecoration2 --key theme "WhiteSur"

    as_user kwriteconfig6 --file kwinrc \
        --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae"

    # Fonte padrão — Inter (mais próxima de SF Pro do macOS)
    as_user kwriteconfig6 --file kdeglobals \
        --group General --key font "Inter,10,-1,5,50,0,0,0,0,0"

    as_user kwriteconfig6 --file kdeglobals \
        --group General --key fixed "JetBrains Mono,10,-1,5,50,0,0,0,0,0"

    # Efeitos de janela — suavidade macOS-like
    as_user kwriteconfig6 --file kwinrc \
        --group Plugins --key blurEnabled "true"

    as_user kwriteconfig6 --file kwinrc \
        --group Plugins --key fadeEnabled "true"

    # Tema GTK (para apps GTK dentro do KDE)
    mkdir -p "$REAL_HOME/.config/gtk-3.0" "$REAL_HOME/.config/gtk-4.0"
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/gtk-3.0" "$REAL_HOME/.config/gtk-4.0"

    cat > "$REAL_HOME/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=WhiteSur-Light
gtk-icon-theme-name=WhiteSur
gtk-cursor-theme-name=WhiteSur-cursors
gtk-font-name=Inter 10
gtk-application-prefer-dark-theme=0
EOF

    cat > "$REAL_HOME/.config/gtk-4.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=WhiteSur-Light
gtk-icon-theme-name=WhiteSur
gtk-cursor-theme-name=WhiteSur-cursors
gtk-font-name=Inter 10
gtk-application-prefer-dark-theme=0
EOF

    chown "$REAL_USER:$REAL_USER" \
        "$REAL_HOME/.config/gtk-3.0/settings.ini" \
        "$REAL_HOME/.config/gtk-4.0/settings.ini"

    ok "Configurações KDE aplicadas"
}

configure_plank() {
    step "Configurando Plank Dock"

    local plank_dir="$REAL_HOME/.config/plank/dock1"
    mkdir -p "$plank_dir/launchers"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/plank"

    # Configuração do Plank: dock na base, tema transparente, ícones 48px
    cat > "$plank_dir/settings" << 'EOF'
[PlankDockPreferences]
#Whether to show only windows of the current workspace.
CurrentWorkspaceOnly=false
#The size of dock icons (in pixels).
IconSize=48
#If true, the dock will lock its items in place and not show an 'eject' button for removable devices.
LockItems=false
#The monitor plug name to display the dock on, or blank to use the primary monitor.
Monitor=
#The filename of the theme to use for the dock.
Theme=Transparent
#The position for the dock on the monitor.
Position=3
#Whether to show 'keep in dock' in the right-click menu.
ShowDockItem=false
#The number of seconds to delay before hiding the dock.
HideDelay=0
#The type of hiding to use for the dock.
HideMode=1
#The number of seconds to wait before unhiding the dock.
UnhideDelay=0
#The alignment mode for the launchers on the dock.
Alignment=3
#The visual offset from the alignment point.
Offset=0
#If true, zoom dock items on hover.
ZoomEnabled=true
#The maximum zoom percent for the dock items.
ZoomPercent=150
#The number of pixels from the screen edge the dock will sit at.
GapSize=4
EOF

    chown "$REAL_USER:$REAL_USER" "$plank_dir/settings"

    # Tema WhiteSur para Plank (vem no repo GTK)
    local plank_theme_src="$BUILD_DIR/whitesur-gtk/src/other/plank"
    if [[ -d "$plank_theme_src" ]]; then
        mkdir -p "$REAL_HOME/.local/share/plank/themes"
        cp -r "$plank_theme_src"/* "$REAL_HOME/.local/share/plank/themes/" 2>/dev/null || true
        chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.local/share/plank"
        ok "Tema WhiteSur aplicado ao Plank"
    else
        warn "Tema Plank não encontrado — usando Transparent"
    fi

    # Autostart do Plank na sessão KDE
    local autostart_dir="$REAL_HOME/.config/autostart"
    mkdir -p "$autostart_dir"
    cat > "$autostart_dir/plank.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Comment=Dock estilo macOS
Exec=plank
Icon=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

    chown -R "$REAL_USER:$REAL_USER" "$autostart_dir/plank.desktop"
    ok "Plank configurado e adicionado ao autostart"
}

# ─── Limpeza ──────────────────────────────────────────────────────────────────

cleanup() {
    info "Limpando arquivos temporários..."
    rm -rf "$BUILD_DIR"
    ok "Limpeza concluída"
}

print_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║   Módulo 02-theme concluído com êxito!   ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Tema GTK:${NC}     WhiteSur-Light / WhiteSur-Dark"
    echo -e "  ${BOLD}Tema KDE:${NC}     WhiteSur"
    echo -e "  ${BOLD}Ícones:${NC}       WhiteSur"
    echo -e "  ${BOLD}Cursores:${NC}     WhiteSur-cursors"
    echo -e "  ${BOLD}Dock:${NC}         Plank (autostart configurado)"
    echo -e "  ${BOLD}Widget style:${NC} Kvantum"
    echo ""
    echo -e "  ${YELLOW}Reinicie a sessão KDE para ver todas as mudanças.${NC}"
    echo -e "  ${YELLOW}Ajustes finos podem ser feitos em: Configurações do Sistema${NC}"
    echo ""
    log "Módulo 02-theme finalizado com sucesso"
}

# ─── Execução ─────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║   Tchesco OS — Módulo 02: Tema macOS        ║${NC}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════╝${NC}"
    echo ""

    check_root
    get_real_user
    check_internet
    install_deps
    clone_repos
    install_gtk_theme
    install_kde_theme
    install_icons
    install_cursors
    install_plymouth
    apply_kde_config
    configure_plank
    cleanup
    print_summary
}

main "$@"
