#!/usr/bin/env bash
# Módulo 02 — Tema visual macOS (WhiteSur + Plank)
# Fase 3 do roadmap: tema GTK, KDE Plasma 6, ícones, cursores, dock e Plymouth
#
# NOTA Latte Dock: abandonado, sem suporte para Plasma 6.
# Alternativa: Plank dock (GTK, leve, estável no Plasma 6).

set -euo pipefail

# ─── Constantes ───────────────────────────────────────────────────────────────

LOG_FILE="/var/log/tchesco-install.log"
BUILD_DIR=""  # definido em get_real_user() após identificar REAL_HOME
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

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

    # Desabilita override automático de tema do Kubuntu (causa crítica de nada mudar)
    as_user kwriteconfig6 --file kdeglobals \
        --group KDE --key AutomaticLookAndFeel "false"
    as_user kwriteconfig6 --file kdeglobals \
        --group KDE --key LookAndFeelPackage "com.github.vinceliuice.WhiteSur"

    # Desativa ksplash do WhiteSur — mostra logo Apple durante login
    as_user kwriteconfig6 --file ksplashrc \
        --group KSplash --key Theme "None"

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

install_tchesco_icon() {
    step "Instalando ícones Tchesco OS"

    local logo_dir="$REPO_DIR/tchesco-logo-pack/tchesco-os/assets/logo"
    local icon_src="$logo_dir/tchesco-icon-kde.svg"
    local horizontal_src="$logo_dir/tchesco-logo-horizontal.svg"

    if [[ ! -f "$icon_src" ]]; then
        warn "Ícone não encontrado em $icon_src — pulando"
        return 0
    fi

    local dest_user="$REAL_HOME/.local/share/icons/hicolor/scalable/apps"
    as_user mkdir -p "$dest_user"

    # Ícone quadrado (T) — usado internamente
    as_user cp "$icon_src" "$dest_user/tchesco.svg"
    cp "$icon_src" /usr/share/pixmaps/tchesco.svg

    # Logo horizontal — usado no botão do Kickoff na barra superior
    if [[ -f "$horizontal_src" ]]; then
        as_user cp "$horizontal_src" "$dest_user/tchesco-horizontal.svg"
        cp "$horizontal_src" /usr/share/pixmaps/tchesco-horizontal.svg
        ok "Logo horizontal instalado: tchesco-horizontal"
    fi

    command -v gtk-update-icon-cache &>/dev/null && \
        as_user gtk-update-icon-cache -qf "$REAL_HOME/.local/share/icons/hicolor" 2>/dev/null || true

    ok "Ícones Tchesco instalados"
}

configure_top_panel() {
    step "Configurando painéis estilo macOS (Wayland-compatible)"

    local icon_path="$REAL_HOME/.local/share/icons/hicolor/scalable/apps/tchesco.svg"
    local script_path="$REAL_HOME/.local/bin/tchesco-panel-setup.sh"
    local flag_path="$REAL_HOME/.tchesco-panel-done"
    local autostart_path="$REAL_HOME/.config/autostart/tchesco-panel-setup.desktop"

    # Remove Plank do autostart — não funciona em Wayland (Kubuntu 26.04 padrão)
    rm -f "$REAL_HOME/.config/autostart/plank.desktop" 2>/dev/null || true

    as_user mkdir -p "$REAL_HOME/.local/bin"

    # Reseta flag para o script rodar novamente com a configuração atualizada
    rm -f "$flag_path" 2>/dev/null || true

    # Escreve script com heredoc literal (sem expansão) + sed injeta os paths
    cat > "$script_path" << 'PANEL_EOF'
#!/bin/bash
# Configura painéis macOS estilo Tchesco OS — executa uma vez no login
FLAG="__FLAG_PATH__"
[[ -f "$FLAG" ]] && exit 0

# Ubuntu 26.04 usa qdbus6 (não qdbus)
QDBUS="qdbus6"

# Aguarda Plasma carregar (máximo 90s) e obtém DBUS da sessão gráfica
# O systemd não herda DBUS_SESSION_BUS_ADDRESS — precisa descobrir manualmente
for i in $(seq 1 45); do
    sleep 2
    # Descobre DBUS_SESSION_BUS_ADDRESS da sessão plasmashell
    PLASMA_PID=$(pgrep -u "$USER" plasmashell 2>/dev/null | head -1)
    if [[ -n "$PLASMA_PID" ]]; then
        DBUS_ADDR=$(cat /proc/"$PLASMA_PID"/environ 2>/dev/null \
            | tr '\0' '\n' \
            | grep DBUS_SESSION_BUS_ADDRESS \
            | cut -d= -f2-)
        if [[ -n "$DBUS_ADDR" ]]; then
            export DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR"
            # Testa se o evaluateScript responde de verdade
            TEST=$($QDBUS org.kde.plasmashell /PlasmaShell evaluateScript "panels().length" 2>/dev/null)
            [[ -n "$TEST" ]] && break
        fi
    fi
done

# Desabilita override de tema automático do Kubuntu
kwriteconfig6 --file kdeglobals --group KDE --key AutomaticLookAndFeel false

# Cria painéis via Plasma JS API
$QDBUS org.kde.plasmashell /PlasmaShell evaluateScript "
// Remove todos os painéis existentes (painel padrão Kubuntu)
panels().forEach(function(p) { p.remove() })

// ── BARRA SUPERIOR estilo macOS ──────────────────────────────────
var top = new Panel
top.location = 'top'
top.height = 40
top.hiding = 'none'

// Path completo garante que o ícone é encontrado independente do cache
var launcher = top.addWidget('org.kde.plasma.kickoff')
launcher.currentConfigGroup = ['General']
launcher.writeConfig('icon', '__ICON_PATH__')

// Global Menu: menus da app ativa aparecem na barra, igual ao macOS
top.addWidget('org.kde.plasma.appmenu')
top.addWidget('org.kde.plasma.panelspacer')

// Lupa estilo Spotlight do macOS (Application Dashboard com busca)
var search = top.addWidget('org.kde.plasma.kickerdash')
search.currentConfigGroup = ['General']
search.writeConfig('icon', 'search')

top.addWidget('org.kde.plasma.systemtray')
top.addWidget('org.kde.plasma.digitalclock')

// ── DOCK CENTRALIZADO estilo macOS ───────────────────────────────
// KDE Plasma 6 nativo: funciona em Wayland, suporta flutuante e centralizado
var dock = new Panel
dock.location = 'bottom'
dock.height = 72
dock.hiding = 'dodgewindows'
dock.alignment = 'center'
dock.lengthMode = 'fit'
dock.floating = true

// Icon-only Task Manager (igual ao Dock do macOS)
var tasks = dock.addWidget('org.kde.plasma.icontasks')
tasks.currentConfigGroup = ['General']
tasks.writeConfig('launchers', 'applications:org.kde.dolphin.desktop,applications:org.kde.konsole.desktop,applications:systemsettings.desktop,applications:org.kde.kate.desktop')
tasks.writeConfig('iconSpacing', '1')
" 2>/dev/null

touch "$FLAG"
PANEL_EOF

    sed -i "s|__FLAG_PATH__|$flag_path|g" "$script_path"
    sed -i "s|__ICON_PATH__|$icon_path|g" "$script_path"
    chmod +x "$script_path"
    chown "$REAL_USER:$REAL_USER" "$script_path"

    cat > "$autostart_path" << EOF
[Desktop Entry]
Type=Application
Name=Tchesco Panel Setup
Exec=$script_path
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
    chown "$REAL_USER:$REAL_USER" "$autostart_path"

    ok "Painéis configurados — barra top + dock macOS no próximo login"
}

configure_plank() {
    step "Configurando Plank Dock"

    local plank_dir="$REAL_HOME/.config/plank/dock1"
    local launchers_dir="$plank_dir/launchers"
    as_user mkdir -p "$launchers_dir"

    # Dock centralizado, flutuante (gap 8px), ícones 52px, zoom no hover
    cat > "$plank_dir/settings" << 'EOF'
[PlankDockPreferences]
CurrentWorkspaceOnly=false
IconSize=52
LockItems=false
Monitor=
Theme=Transparent
Position=3
ShowDockItem=false
HideDelay=0
HideMode=0
UnhideDelay=0
Alignment=3
Offset=0
ZoomEnabled=true
ZoomPercent=150
GapSize=8
EOF
    chown "$REAL_USER:$REAL_USER" "$plank_dir/settings"

    # Tema WhiteSur para Plank (vem no repo GTK)
    local plank_theme_src="$BUILD_DIR/whitesur-gtk/src/other/plank"
    if [[ -d "$plank_theme_src" ]]; then
        as_user mkdir -p "$REAL_HOME/.local/share/plank/themes"
        cp -r "$plank_theme_src"/* "$REAL_HOME/.local/share/plank/themes/" 2>/dev/null || true
        chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.local/share/plank"
        ok "Tema WhiteSur aplicado ao Plank"
    else
        warn "Tema Plank não encontrado — usando Transparent"
    fi

    # Launchers padrão — apps disponíveis no Kubuntu 26.04
    local -A dock_items=(
        ["dolphin"]="org.kde.dolphin.desktop"
        ["konsole"]="org.kde.konsole.desktop"
        ["settings"]="systemsettings.desktop"
        ["kate"]="org.kde.kate.desktop"
    )

    for name in dolphin konsole settings kate; do
        local desktop="${dock_items[$name]}"
        if [[ -f "/usr/share/applications/$desktop" ]]; then
            cat > "$launchers_dir/${name}.dockitem" << EOF
[PlankDockItemPreferences]
Launcher=file:///usr/share/applications/$desktop
EOF
            chown "$REAL_USER:$REAL_USER" "$launchers_dir/${name}.dockitem"
        fi
    done

    # Autostart do Plank
    local autostart_dir="$REAL_HOME/.config/autostart"
    mkdir -p "$autostart_dir"
    cat > "$autostart_dir/plank.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
Icon=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
    chown "$REAL_USER:$REAL_USER" "$autostart_dir/plank.desktop"

    ok "Plank configurado: centralizado, flutuante, com launchers"
}

configure_sddm() {
    step "Configurando tela de login SDDM (Tchesco OS)"

    local logo_src="$REPO_DIR/tchesco-logo-pack/tchesco-os/assets/logo/tchesco-logo-horizontal.svg"

    if [[ ! -f "$logo_src" ]]; then
        warn "Logo não encontrado para SDDM — pulando"
        return 0
    fi

    # Usa tema breeze (KDE nativo, sem estética Apple)
    # e injeta logo + cor Tchesco
    local sddm_theme_dir="/usr/share/sddm/themes/breeze"
    cp "$logo_src" "$sddm_theme_dir/default-logo.svg"

    cat > "$sddm_theme_dir/theme.conf" << 'EOF'
[General]
showlogo=shown
logo=/usr/share/sddm/themes/breeze/default-logo.svg
type=color
color=#0e1117
fontSize=11
background=
needsFullUserModel=false
showClock=true
EOF

    # Ativa o tema breeze no SDDM
    if grep -q "Current=" /etc/sddm.conf.d/*.conf 2>/dev/null; then
        sed -i "s/^Current=.*/Current=breeze/" /etc/sddm.conf.d/*.conf
    else
        printf "[Theme]\nCurrent=breeze\n" >> /etc/sddm.conf
    fi

    ok "Tela de login: breeze + logo Tchesco + fundo escuro"
}

fix_apple_icons() {
    step "Removendo ícones estilo Apple"

    # Substitui o ícone do Dolphin no WhiteSur (que imita o Finder do macOS)
    # pelo ícone de pasta padrão do Breeze (azul, sem referência à Apple)
    local breeze_folder="/usr/share/icons/breeze/places/96/folder.svg"
    local whitesur_dolphin="$REAL_HOME/.local/share/icons/WhiteSur/apps/scalable/org.kde.dolphin.svg"

    if [[ -f "$breeze_folder" && -f "$whitesur_dolphin" ]]; then
        cp "$breeze_folder" "$whitesur_dolphin"
        chown "$REAL_USER:$REAL_USER" "$whitesur_dolphin"
        ok "Ícone do Dolphin substituído (sem Finder Apple)"
    else
        warn "Ícone do Dolphin ou Breeze não encontrado — pulando"
    fi
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
    echo -e "  ${BOLD}Dock:${NC}         Plank — centralizado, flutuante, 4 apps"
    echo -e "  ${BOLD}Barra top:${NC}    Estilo macOS — será criada no próximo login"
    echo -e "  ${BOLD}Ícone menu:${NC}   Logo Tchesco OS (substituiu a maçã)"
    echo -e "  ${BOLD}Widget style:${NC} Kvantum"
    echo ""
    echo -e "  ${YELLOW}Faça logout e login novamente para ver todas as mudanças.${NC}"
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
    install_tchesco_icon
    apply_kde_config
    configure_sddm
    fix_apple_icons
    configure_top_panel
    configure_plank
    cleanup
    print_summary
}

main "$@"
