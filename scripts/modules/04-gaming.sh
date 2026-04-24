#!/usr/bin/env bash
# Módulo 04 — Pilar Jogos
# Fase 5 do roadmap: Steam, Lutris, GameMode, MangoHud, ProtonUp-Qt, Heroic

set -euo pipefail

LOG_FILE="/var/log/tchesco-install.log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [04-gaming] $*" >> "$LOG_FILE"; }
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
    log "Iniciando módulo 04-gaming"
    log "════════════════════════════════════"
}

# ─── Arquitetura i386 ─────────────────────────────────────────────────────────

enable_i386() {
    step "Habilitando arquitetura i386 (32-bit)"

    if dpkg --print-foreign-architectures | grep -q i386; then
        warn "i386 já habilitado"; return 0
    fi

    dpkg --add-architecture i386
    apt-get update -qq >> "$LOG_FILE" 2>&1
    ok "Arquitetura i386 habilitada"
}

# ─── Drivers GPU ──────────────────────────────────────────────────────────────

install_gpu_drivers() {
    step "Detectando e instalando drivers GPU"

    if ! dpkg -s ubuntu-drivers-common &>/dev/null 2>&1; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ubuntu-drivers-common >> "$LOG_FILE" 2>&1
    fi

    # Mesa/OpenGL genérico sempre útil (funciona em VM e hardware)
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        mesa-utils \
        mesa-vulkan-drivers \
        "mesa-vulkan-drivers:i386" \
        libgl1-mesa-dri \
        >> "$LOG_FILE" 2>&1

    local detected
    detected=$(ubuntu-drivers devices 2>/dev/null | grep "recommended" | head -1 || true)

    if [[ -z "$detected" ]]; then
        warn "Nenhum driver proprietário encontrado (VM ou GPU integrada) — Mesa instalado"
        return 0
    fi

    info "Driver recomendado detectado. Instalando..."
    ubuntu-drivers autoinstall >> "$LOG_FILE" 2>&1 && ok "Drivers proprietários instalados" \
        || warn "Falha nos drivers proprietários — continuando com Mesa"
}

# ─── Vulkan ───────────────────────────────────────────────────────────────────

install_vulkan() {
    step "Instalando suporte Vulkan"

    local packages=(
        vulkan-tools
        libvulkan1
        "libvulkan1:i386"
    )

    local to_install=()
    for pkg in "${packages[@]}"; do
        dpkg -s "$pkg" &>/dev/null 2>&1 || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${to_install[@]}" >> "$LOG_FILE" 2>&1
    fi

    ok "Suporte Vulkan instalado"
}

# ─── Flatpak + Flathub ────────────────────────────────────────────────────────

install_flatpak() {
    step "Configurando Flatpak + Flathub"

    if ! dpkg -s flatpak &>/dev/null 2>&1; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq flatpak >> "$LOG_FILE" 2>&1
    else
        warn "Flatpak já instalado"
    fi

    if ! flatpak remotes 2>/dev/null | grep -q flathub; then
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
            >> "$LOG_FILE" 2>&1
        ok "Flathub configurado"
    else
        warn "Flathub já configurado"
    fi

    ok "Flatpak pronto"
}

# ─── Steam ────────────────────────────────────────────────────────────────────

install_steam() {
    step "Instalando Steam"

    if dpkg -s steam-installer &>/dev/null 2>&1 || dpkg -s steam &>/dev/null 2>&1; then
        warn "Steam já instalado"; return 0
    fi

    info "Habilitando multiverse..."
    add-apt-repository -y multiverse >> "$LOG_FILE" 2>&1
    apt-get update -qq >> "$LOG_FILE" 2>&1

    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq steam-installer >> "$LOG_FILE" 2>&1
    ok "Steam instalado"
}

# ─── Lutris ───────────────────────────────────────────────────────────────────

install_lutris() {
    step "Instalando Lutris"

    # PPA Lutris ainda não suporta Ubuntu 26.04 — usa Flatpak
    if flatpak list --app 2>/dev/null | grep -q "net.lutris.Lutris"; then
        warn "Lutris já instalado (Flatpak)"; return 0
    fi

    info "Instalando Lutris via Flatpak..."
    flatpak install -y --noninteractive flathub net.lutris.Lutris >> "$LOG_FILE" 2>&1 \
        && ok "Lutris instalado" \
        || warn "Falha ao instalar Lutris — continuando"
}

# ─── GameMode ─────────────────────────────────────────────────────────────────

install_gamemode() {
    step "Instalando GameMode"

    if dpkg -s gamemode &>/dev/null 2>&1; then
        warn "GameMode já instalado"; return 0
    fi

    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq gamemode >> "$LOG_FILE" 2>&1

    # Grupo gamemode criado pelo pacote — adiciona usuário
    usermod -aG gamemode "$REAL_USER" >> "$LOG_FILE" 2>&1 || true

    ok "GameMode instalado"
}

# ─── MangoHud ─────────────────────────────────────────────────────────────────

install_mangohud() {
    step "Instalando MangoHud (HUD de FPS/GPU)"

    if dpkg -s mangohud &>/dev/null 2>&1; then
        warn "MangoHud já instalado"; return 0
    fi

    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mangohud >> "$LOG_FILE" 2>&1 \
        && ok "MangoHud (64-bit) instalado" \
        || { warn "MangoHud não disponível — pulando"; return 0; }

    # i386 opcional — nem sempre disponível
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "mangohud:i386" >> "$LOG_FILE" 2>&1 \
        && ok "MangoHud i386 instalado" \
        || warn "MangoHud i386 não disponível — apenas 64-bit"
}

# ─── CoreCtrl (GPU AMD) ───────────────────────────────────────────────────────

install_corectrl() {
    step "Instalando CoreCtrl (controle de GPU)"

    if dpkg -s corectrl &>/dev/null 2>&1; then
        warn "CoreCtrl já instalado"; return 0
    fi

    if DEBIAN_FRONTEND=noninteractive apt-get install -y -qq corectrl >> "$LOG_FILE" 2>&1; then
        # Polkit: permite controle de GPU sem precisar de senha root
        cat > /etc/polkit-1/rules.d/90-corectrl.rules << 'EOF'
polkit.addRule(function(action, subject) {
    if ((action.id == "org.corectrl.helper.init" ||
         action.id == "org.corectrl.helperkiller.init") &&
        subject.local == true &&
        subject.active == true &&
        subject.isInGroup("users")) {
          return polkit.Result.YES;
    }
});
EOF
        ok "CoreCtrl instalado (polkit configurado)"
    else
        warn "CoreCtrl não disponível nos repositórios — pulando"
    fi
}

# ─── Apps via Flatpak ─────────────────────────────────────────────────────────

install_flatpak_apps() {
    step "Instalando apps de gaming via Flatpak"

    local app_ids=(
        "com.heroicgameslauncher.hgl"
        "net.davidotek.pupgui2"
        "io.github.benjamimgois.goverlay"
    )
    local app_names=(
        "Heroic Games Launcher"
        "ProtonUp-Qt"
        "GOverlay"
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

# ─── Configuração GameMode ────────────────────────────────────────────────────

configure_gamemode() {
    step "Configurando GameMode"

    if [[ -f /etc/gamemode.ini ]]; then
        warn "GameMode já configurado"; return 0
    fi

    cat > /etc/gamemode.ini << 'EOF'
[general]
reaper_freq=5
desiredgov=performance
igpu_desiredgov=powersave
defaultgov=powersave
softrealtime=auto
renice=10
ioprio=0
inhibit_screensaver=1

[gpu]
apply_gpu_optimisations=accept-responsibility
gpu_device=0
amd_performance_level=high
EOF

    ok "Configuração GameMode criada em /etc/gamemode.ini"
}

# ─── Resumo ───────────────────────────────────────────────────────────────────

print_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║   Módulo 04-gaming concluído com êxito!      ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Lojas:${NC}       Steam, Lutris, Heroic Games Launcher"
    echo -e "  ${BOLD}Performance:${NC} GameMode, MangoHud (HUD de FPS)"
    echo -e "  ${BOLD}Proton:${NC}      ProtonUp-Qt (gerencia versões Proton-GE)"
    echo -e "  ${BOLD}GPU:${NC}         Vulkan, CoreCtrl, GOverlay"
    echo ""
    echo -e "  ${YELLOW}Faça logout/login para ativar o grupo gamemode.${NC}"
    echo -e "  ${YELLOW}Reinicie para carregar drivers GPU (se instalados).${NC}"
    echo ""
    log "Módulo 04-gaming finalizado com sucesso"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║   Tchesco OS — Módulo 04: Gaming              ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    init_log
    check_root
    get_real_user
    enable_i386
    install_gpu_drivers
    install_vulkan
    install_flatpak
    install_steam
    install_lutris
    install_gamemode
    install_mangohud
    install_corectrl
    install_flatpak_apps
    configure_gamemode
    print_summary
}

main "$@"
