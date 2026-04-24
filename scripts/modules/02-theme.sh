#!/usr/bin/env bash
# Módulo 02 — Tema visual macOS (WhiteSur + Plank dock em X11)
# Fase 3 do roadmap: tema GTK, KDE Plasma 6, ícones, cursores, painéis, splash e dock
#
# Sessão: X11 (plasmax11) — escolha consciente, não Wayland
#   Motivo: Plasma 6 Wayland tem bugs com Global Menu de apps GTK (Firefox) e
#   Plank não funciona em Wayland.
#
# Barra superior: painel nativo Plasma 6 (T + Global Menu + busca + systray + clock)
# Dock inferior: Plank (GTK, X11 only) — comportamento macOS real:
#   centralizado, autohide, zoom no hover, flutuante, transparente.

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
        qt6-style-kvantum   # Engine de temas Qt para widgets mais fiéis ao macOS
        sassc               # Compilador SCSS (necessário para WhiteSur GTK)
        libglib2.0-dev-bin  # glib-compile-schemas (WhiteSur GTK)
        libgtk-4-dev        # Headers GTK4
        gnome-themes-extra  # Temas extras GTK
        gtk2-engines-murrine
        gtk2-engines-pixbuf
        # Sessão X11 (escolha consciente do Tchesco OS — Wayland tem bugs de UX)
        plasma-session-x11
        kwin-x11
        # Dock estilo macOS (funciona em X11)
        plank
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

    # Substitui logo Apple no splash do WhiteSur pelo ícone Tchesco
    local kde_icon="$REPO_DIR/tchesco-logo-pack/tchesco-os/assets/logo/tchesco-icon-kde.svg"
    for variant in WhiteSur WhiteSur-alt WhiteSur-dark; do
        local splash_logo="$REAL_HOME/.local/share/plasma/look-and-feel/com.github.vinceliuice.$variant/contents/splash/images/logo.svg"
        [[ -f "$splash_logo" && -f "$kde_icon" ]] && cp "$kde_icon" "$splash_logo"
    done

    # Gera background escuro Tchesco (substitui wallpaper macOS Monterey)
    # REAL_HOME passado via env pois o Python roda como root e ~ resolveria para /root
    REAL_HOME="$REAL_HOME" python3 - << 'PYEOF'
from PIL import Image
import os, shutil

w, h = 1920, 1080
img = Image.new("RGBA", (w, h))
pixels = img.load()

for y in range(h):
    for x in range(w):
        rx, ry = x / w, y / h
        r = min(30, int(10 + rx * 3 + ry * 5))
        g = min(52, int(17 + rx * 15 + ry * 20))
        b = min(98, int(40 + rx * 30 + ry * 28))
        pixels[x, y] = (r, g, b, 255)

cx, cy = w // 2, h // 2
max_dist = (cx**2 + cy**2) ** 0.5
for y in range(h):
    for x in range(w):
        dist = ((x-cx)**2 + (y-cy)**2) ** 0.5
        factor = max(0, 1 - dist / (max_dist * 0.6))
        r, g, b, a = pixels[x, y]
        pixels[x, y] = (min(255, r + int(factor*8)), min(255, g + int(factor*10)), min(255, b + int(factor*40)), a)

bg = "/tmp/tchesco-splash-bg.png"
img.save(bg)
# HOME do usuário real passado via variável de ambiente (script roda como root)
import os as _os
real_home = _os.environ.get("REAL_HOME", _os.path.expanduser("~"))
base = _os.path.join(real_home, ".local/share/plasma/look-and-feel")
for v in ["WhiteSur", "WhiteSur-alt", "WhiteSur-dark"]:
    dest = _os.path.join(base, f"com.github.vinceliuice.{v}/contents/splash/images/background.png")
    _os.path.exists(_os.path.dirname(dest)) and shutil.copy(bg, dest)
PYEOF

    # Mantém o ksplash WhiteSur ativo (agora com logo Tchesco e fundo Tchesco)
    as_user kwriteconfig6 --file ksplashrc \
        --group KSplash --key Theme "com.github.vinceliuice.WhiteSur"

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

setup_global_menu() {
    step "Configurando Global Menu (menus da app no topo)"

    # GTK_MODULES precisa chegar aos processos via múltiplos caminhos:
    # 1) /etc/profile.d/*.sh — login shells (sh, bash)
    # 2) ~/.config/plasma-workspace/env/*.sh — Plasma startup (Wayland)
    # 3) /etc/environment — fallback para sistemas que leem (limitado)
    # NÃO usar só ~/.config/environment.d — Plasma Wayland ignora esse caminho.

    cat > /etc/profile.d/tchesco-gtk-modules.sh << 'EOF'
export GTK_MODULES=appmenu-gtk-module
EOF
    chmod +x /etc/profile.d/tchesco-gtk-modules.sh

    local plasma_env="$REAL_HOME/.config/plasma-workspace/env"
    as_user mkdir -p "$plasma_env"
    cat > "$plasma_env/gtk-modules.sh" << 'EOF'
#!/bin/sh
export GTK_MODULES=appmenu-gtk-module
EOF
    chmod +x "$plasma_env/gtk-modules.sh"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/plasma-workspace"

    if ! grep -q "^GTK_MODULES" /etc/environment 2>/dev/null; then
        echo "GTK_MODULES=appmenu-gtk-module" >> /etc/environment
    fi

    # Garante que appmenu-gtk3-module está instalado
    dpkg -s appmenu-gtk3-module &>/dev/null 2>&1 || \
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq appmenu-gtk3-module >> "$LOG_FILE" 2>&1

    ok "Global Menu configurado em /etc/profile.d + plasma-workspace/env"
}

replace_whitesur_apple_wallpapers() {
    step "Substituindo wallpapers macOS do WhiteSur por Tchesco escuro"

    # WhiteSur/contents/logout/Logout.qml usa wallpapers/WhiteSur-*/contents/images/*.jpg
    # como fundo da tela de logout. Esses JPGs são o wallpaper macOS Monterey (rosa/laranja).
    # Substituímos por um gradiente escuro Tchesco.

    REAL_HOME="$REAL_HOME" python3 - << 'PYEOF' >> "$LOG_FILE" 2>&1
from PIL import Image
import os, glob, shutil

real_home = os.environ.get("REAL_HOME", os.path.expanduser("~"))

w, h = 3840, 2160
img = Image.new("RGBA", (w, h))
px = img.load()
for y in range(h):
    for x in range(w):
        rx, ry = x / w, y / h
        r = min(30, int(10 + rx * 3 + ry * 5))
        g = min(52, int(17 + rx * 15 + ry * 20))
        b = min(98, int(40 + rx * 30 + ry * 28))
        px[x, y] = (r, g, b, 255)

tmp = "/tmp/tchesco-wallpaper.jpg"
img.convert("RGB").save(tmp, "JPEG", quality=90)

wp_root = os.path.join(real_home, ".local/share/wallpapers")
for wp_dir in glob.glob(os.path.join(wp_root, "WhiteSur*")):
    img_dir = os.path.join(wp_dir, "contents", "images")
    if os.path.isdir(img_dir):
        for img_file in os.listdir(img_dir):
            shutil.copy(tmp, os.path.join(img_dir, img_file))
PYEOF

    ok "Wallpapers WhiteSur substituídos por Tchesco (sem cores Apple)"
}

setup_firefox_global_menu() {
    step "Configurando Firefox para Global Menu"

    # Em X11, GTK_MODULES=appmenu-gtk-module permite export de menus via DBus.
    # Sessão toda é X11 (plasmax11) — não precisa de workaround no .desktop.

    local ff_root="/usr/lib/firefox"
    [[ ! -d "$ff_root" ]] && { warn "Firefox deb não encontrado — pulando"; return 0; }

    # policies.json (defaults ficam mutáveis pelo usuário)
    mkdir -p "$ff_root/distribution"
    cat > "$ff_root/distribution/policies.json" << 'EOF'
{
  "policies": {
    "Preferences": {
      "ui.use_unity_menubar": {
        "Value": true,
        "Status": "default"
      },
      "browser.tabs.inTitlebar": {
        "Value": 0,
        "Status": "default"
      }
    }
  }
}
EOF

    # autoconfig aplica antes da UI carregar
    cat > "$ff_root/defaults/pref/autoconfig.js" << 'EOF'
pref("general.config.filename", "tchesco.cfg");
pref("general.config.obscure_value", 0);
EOF

    cat > "$ff_root/tchesco.cfg" << 'EOF'
// Tchesco OS — Firefox config defaults
defaultPref("ui.use_unity_menubar", true);
defaultPref("browser.tabs.inTitlebar", 0);
EOF

    ok "Firefox configurado (Global Menu em X11)"
}

switch_sddm_to_x11() {
    step "Configurando SDDM para sessão X11 (plasmax11)"

    # O Kubuntu 26.04 vem com DisplayServer=wayland.
    # Tchesco OS usa X11 para garantir AutoHide do dock + Global Menu do Firefox funcionando.

    cat > /etc/sddm.conf.d/10-wayland.conf << 'EOF'
[General]
DisplayServer=x11

[X11]
EOF

    # Força plasmax11 como sessão do autologin (garante que loga em X11 todo boot)
    cat > /etc/sddm.conf.d/30-tchesco-x11.conf << EOF
[Autologin]
User=$REAL_USER
Session=plasmax11
Relogin=false
EOF

    # Esconde a sessão Wayland (não aparece como opção na tela de login)
    # Via override em /etc/xdg (não modifica arquivo do pacote plasma-workspace)
    mkdir -p /etc/xdg/wayland-sessions
    cat > /etc/xdg/wayland-sessions/plasma.desktop << 'EOF'
[Desktop Entry]
Hidden=true
EOF

    # Limpa cache do SDDM que lembra a última sessão escolhida pelo usuário
    rm -rf "/var/lib/sddm/.cache/$REAL_USER" 2>/dev/null || true

    # Se tiver Session=plasma (Wayland) em outros conf, troca para plasmax11
    if grep -rq "^Session=plasma$" /etc/sddm.conf /etc/sddm.conf.d/ 2>/dev/null; then
        sed -i "s/^Session=plasma$/Session=plasmax11/g" /etc/sddm.conf 2>/dev/null || true
        sed -i "s/^Session=plasma$/Session=plasmax11/g" /etc/sddm.conf.d/*.conf 2>/dev/null || true
    fi

    ok "SDDM agora força X11 — Wayland escondido, autologin plasmax11"
}

setup_plymouth() {
    step "Configurando Plymouth (boot/shutdown splash Tchesco)"

    # kubuntu-logo mostra logo com gradiente roxo/azul que lembra cores Apple.
    # breeze-text é minimalista, texto centralizado em fundo escuro — combina com identidade Tchesco.

    local breeze_text="/usr/share/plymouth/themes/breeze-text/breeze-text.plymouth"
    [[ ! -f "$breeze_text" ]] && { warn "breeze-text Plymouth não instalado — pulando"; return 0; }

    # Registra breeze-text no update-alternatives se ainda não estiver
    if ! update-alternatives --list default.plymouth 2>/dev/null | grep -q breeze-text; then
        update-alternatives --install /usr/share/plymouth/themes/default.plymouth \
            default.plymouth "$breeze_text" 100 >> "$LOG_FILE" 2>&1
    fi

    # Ativa breeze-text como padrão
    update-alternatives --set default.plymouth "$breeze_text" >> "$LOG_FILE" 2>&1

    # Regenera initramfs para aplicar no próximo boot
    info "Regenerando initramfs (pode demorar 30-60s)..."
    update-initramfs -u >> "$LOG_FILE" 2>&1

    ok "Plymouth: breeze-text (sem logo Kubuntu/cores macOS)"
}

replace_firefox_snap() {
    step "Substituindo Firefox snap pelo deb (Mozilla oficial)"

    # Firefox snap não exporta menus via DBus — sem Global Menu.
    # Trocamos pelo deb oficial da Mozilla via repositório próprio.
    if [[ ! -f /var/lib/snapd/snaps/firefox_*.snap ]] && \
       dpkg -l firefox 2>/dev/null | grep -q "^ii  firefox.*build1"; then
        warn "Firefox deb já instalado, pulando"
        return 0
    fi

    info "Removendo Firefox snap..."
    snap remove --purge firefox 2>/dev/null || true
    apt-get purge -y -qq firefox >> "$LOG_FILE" 2>&1 || true

    info "Adicionando repositório Mozilla..."
    install -d -m 0755 /etc/apt/keyrings
    wget -qO- https://packages.mozilla.org/apt/repo-signing-key.gpg > \
        /etc/apt/keyrings/packages.mozilla.org.asc

    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
        > /etc/apt/sources.list.d/mozilla.list

    # Prioridade alta para repo Mozilla vencer o snap stub do Ubuntu
    cat > /etc/apt/preferences.d/mozilla << 'EOF'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF

    info "Instalando Firefox deb..."
    apt-get update -qq >> "$LOG_FILE" 2>&1
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq firefox >> "$LOG_FILE" 2>&1

    ok "Firefox deb instalado (com suporte a Global Menu)"
}

configure_top_panel() {
    step "Configurando painéis estilo macOS (config direta em arquivos)"

    # Abordagem: escrever os arquivos de config do Plasma diretamente.
    # Mais robusto que qdbus evaluateScript, que perdia configs ao reiniciar.

    local icon_path="$REAL_HOME/.local/share/icons/hicolor/scalable/apps/tchesco.svg"
    local plasmashellrc="$REAL_HOME/.config/plasmashellrc"
    local appletsrc="$REAL_HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

    as_user mkdir -p "$REAL_HOME/.config"

    # Detecta o Activity ID atual (DBus) ANTES de matar plasmashell.
    # Sem essa chave preenchida corretamente no Containment do desktop, o Plasma
    # ignora nossa config e cria outro Containment auto (com ID aleatório),
    # re-introduzindo o botão "Add Widgets" sobre o Plank.
    local activity_id
    activity_id=$(as_user bash -c 'DISPLAY=:0 qdbus6 org.kde.ActivityManager /ActivityManager/Activities CurrentActivity 2>/dev/null' || true)
    [[ -z "$activity_id" ]] && activity_id=$(cat /proc/sys/kernel/random/uuid)
    log "Activity ID: $activity_id"

    # Mata plasmashell durante a escrita — plasmashell em execução pode sobrescrever
    # o appletsrc ao sair, perdendo nossa config. cleanup_residual_panels() reinicia.
    as_user systemctl --user stop plasma-plasmashell.service 2>/dev/null || true
    pkill -9 plasmashell 2>/dev/null || true
    sleep 2

    # plasmashellrc: dimensões e flags do painel top
    # (dock inferior é o Plank — ver configure_plank_dock)
    cat > "$plasmashellrc" << 'EOF'
[PlasmaViews][Panel 29]
floating=1

[PlasmaViews][Panel 29][Defaults]
thickness=44
EOF
    chown "$REAL_USER:$REAL_USER" "$plasmashellrc"

    # appletsrc: containments (painéis) e applets (widgets).
    # Containment 1: desktop — plugin=org.kde.plasma.folder, activityId preenchido
    # Panel 29 (top): kickoff[tchesco] → appmenu → spacer → kickerdash[search] → systemtray → clock
    cat > "$appletsrc" << EOF
[ActionPlugins][0]
MiddleButton;NoModifier=org.kde.paste
RightButton;NoModifier=org.kde.contextmenu
wheel:Vertical;NoModifier=org.kde.switchdesktop

[Containments][1]
activityId=${activity_id}
formfactor=0
immutability=1
lastScreen=0
location=0
plugin=org.kde.plasma.folder
wallpaperplugin=org.kde.image

[Containments][1][ToolBox]
visibility=none

[Containments][1][Wallpaper][org.kde.image][General]
Image=file://${REAL_HOME}/.local/share/wallpapers/WhiteSur-dark/contents/images/3840x2160.jpg

[Containments][29]
formfactor=2
immutability=1
lastScreen=0
location=3
plugin=org.kde.panel
wallpaperplugin=org.kde.image

[Containments][29][Applets][30]
immutability=1
plugin=org.kde.plasma.kickoff

[Containments][29][Applets][30][Configuration][General]
favoritesPortedToKAstats=true
icon=${icon_path}
useCustomButtonImage=true
customButtonImage=${icon_path}

[Containments][29][Applets][31]
immutability=1
plugin=org.kde.plasma.appmenu

[Containments][29][Applets][32]
immutability=1
plugin=org.kde.plasma.panelspacer

[Containments][29][Applets][33]
immutability=1
plugin=org.kde.plasma.kickerdash

[Containments][29][Applets][33][Configuration][General]
icon=search

[Containments][29][Applets][34]
formfactor=2
immutability=1
lastScreen=0
location=3
plugin=org.kde.plasma.systemtray

[Containments][29][Applets][45]
immutability=1
plugin=org.kde.plasma.digitalclock

[Containments][29][General]
AppletOrder=30;31;32;33;34;45
EOF
    chown "$REAL_USER:$REAL_USER" "$appletsrc"

    # Desabilita override automático de tema do Kubuntu
    as_user kwriteconfig6 --file kdeglobals --group KDE --key AutomaticLookAndFeel false

    ok "Painel superior configurado (44px) — dock Plank via configure_plank_dock()"
}

configure_plank_dock() {
    step "Configurando Plank (dock inferior estilo macOS)"

    # Plank substitui o painel do Plasma porque no Plasma 6 o painel auto-hide
    # centralizado flutuante tem bugs. Plank em X11 entrega exatamente o que queremos.

    local plank_dir="$REAL_HOME/.config/plank/dock1"
    as_user mkdir -p "$plank_dir/launchers"

    # Configuração do dock: centralizado, esconde SÓ quando janela sobrepõe,
    # zoom 150%, posição bottom, tema transparente, ícones 48px
    # HideMode=1 (Intelligent) = visível no desktop vazio, esconde quando app cobre,
    # hover na borda inferior SEMPRE revela (comportamento macOS). HideMode=2 (AutoHide
    # total) foi descartado porque apps maximizados bloqueiam o hover de unhide.
    # PressureReveal=true ajuda em apps fullscreen onde o "edge" vira zona morta.
    cat > "$plank_dir/settings" << 'EOF'
[PlankDockPreferences]
CurrentWorkspaceOnly=false
IconSize=48
LockItems=false
Monitor=
Theme=Transparent
Position=3
ShowDockItem=false
HideDelay=0
HideMode=1
UnhideDelay=0
Alignment=3
Offset=0
ZoomEnabled=true
ZoomPercent=150
PressureReveal=true
PinnedOnly=false
AutoPinning=false
ShowOnClick=false
TooltipsEnabled=true
EOF

    # Cria .desktop customizado "Widgets" — abre seletor de widgets do Plasma
    # (ideia do usuário: em vez de esconder o toolbox, vira ícone do dock)
    local user_apps="$REAL_HOME/.local/share/applications"
    as_user mkdir -p "$user_apps"
    cat > "$user_apps/tchesco-widgets.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Widgets
Name[pt_BR]=Widgets
Comment=Adicionar widgets ao desktop
Comment[pt_BR]=Adicionar widgets ao desktop
Icon=preferences-desktop-plasma
Exec=qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.toggleWidgetExplorer
Categories=Utility;
StartupNotify=false
Terminal=false
EOF
    chown "$REAL_USER:$REAL_USER" "$user_apps/tchesco-widgets.desktop"

    # Dock padrão Tchesco OS — 8 apps fixos (ordem preservada por numeração)
    local -a DOCK_ORDER=(
        "01:firefox:/usr/share/applications/firefox.desktop"
        "02:dolphin:/usr/share/applications/org.kde.dolphin.desktop"
        "03:kate:/usr/share/applications/org.kde.kate.desktop"
        "04:konsole:/usr/share/applications/org.kde.konsole.desktop"
        "05:vscode:/usr/share/applications/code.desktop"
        "06:spectacle:/usr/share/applications/org.kde.spectacle.desktop"
        "07:settings:/usr/share/applications/systemsettings.desktop"
        "08:widgets:$user_apps/tchesco-widgets.desktop"
    )

    for entry in "${DOCK_ORDER[@]}"; do
        IFS=':' read -r num name path <<< "$entry"
        [[ -f "$path" ]] || continue
        cat > "$plank_dir/launchers/${num}_${name}.dockitem" << EOF
[PlankDockItemPreferences]
Launcher=file://${path}
EOF
    done

    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/plank"

    # Garante posse do autostart dir antes de criar .desktop
    local autostart_dir="$REAL_HOME/.config/autostart"
    as_user mkdir -p "$autostart_dir"
    chown "$REAL_USER:$REAL_USER" "$autostart_dir"

    cat > "$autostart_dir/plank.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
Icon=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
X-KDE-autostart-after=panel
EOF
    chown "$REAL_USER:$REAL_USER" "$autostart_dir/plank.desktop"

    # Remove artefatos de tentativas anteriores de esconder o Plasma Toolbox via XUnmap
    # (hoje o botão "Add Widgets" é prevenido via limpeza de Containments residuais em
    # cleanup_residual_panels(), então o daemon/helper não é mais necessário)
    rm -f "$REAL_HOME/.local/bin/tchesco-unmap" \
          "$REAL_HOME/.local/bin/tchesco-hide-toolbox.sh" \
          "$autostart_dir/tchesco-hide-toolbox.desktop"

    ok "Plank configurado: 8 apps + autohide + zoom"
}

# Plasma 6 cria auto um Panel vazio na location=4 (bottom) mesmo quando só definimos
# o top panel no appletsrc. Esse panel residual renderiza o ToolBoxButton "Add Widgets"
# sobre o Plank. Removemos todo Containment location=4 sem applets configurados.
cleanup_residual_panels() {
    step "Removendo painéis residuais do Plasma (evita 'Add Widgets' fantasma sobre o Plank)"

    as_user systemctl --user stop plasma-plasmashell.service 2>/dev/null || true
    pkill -9 plasmashell 2>/dev/null || true
    sleep 2

    REAL_HOME="$REAL_HOME" python3 << 'PYEOF'
import os, re
home = os.environ["REAL_HOME"]
files = [
    f"{home}/.config/plasmashellrc",
    f"{home}/.config/plasma-org.kde.plasma.desktop-appletsrc",
]
# Qualquer Containment ou Panel com id != 1,29 (nossos) é residual (52=desktop auto, 55=panel auto)
KEEP_IDS = {"1", "29"}
for f in files:
    if not os.path.exists(f):
        continue
    with open(f) as h:
        content = h.read()
    # Split em seções por [Header]
    blocks = re.split(r'(?=^\[)', content, flags=re.MULTILINE)
    out = []
    for b in blocks:
        m = re.match(r'^\[(Containments|PlasmaViews)\](?:\[Panel )?\[?(\d+)\]?', b)
        if m and m.group(2) not in KEEP_IDS:
            continue
        out.append(b)
    with open(f, "w") as h:
        h.write("".join(out))
print("Containments/Panels residuais removidos")
PYEOF

    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/plasmashellrc" \
                                  "$REAL_HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

    # Reinicia plasmashell em background como usuário real
    as_user bash -c 'export DISPLAY=:0; nohup plasmashell --replace > /dev/null 2>&1 & disown' || true
    sleep 3

    ok "Painéis residuais removidos e plasmashell reiniciado"
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
    echo -e "  ${BOLD}Dock:${NC}         KDE icontasks — centralizado, flutuante, 4 apps"
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
    setup_plymouth
    fix_apple_icons
    replace_whitesur_apple_wallpapers
    setup_global_menu
    replace_firefox_snap
    setup_firefox_global_menu
    switch_sddm_to_x11
    configure_top_panel
    configure_plank_dock
    cleanup_residual_panels
    cleanup
    print_summary
}

main "$@"
