#!/usr/bin/env bash
# Módulo 06 — Compatibilidade Windows
# Fase 7 do roadmap: Wine Staging, Winetricks, Bottles

set -euo pipefail

LOG_FILE="/var/log/tchesco-install.log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [06-wine] $*" >> "$LOG_FILE"; }
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
    log "Iniciando módulo 06-wine"
    log "════════════════════════════════════"
}

# ─── Wine ─────────────────────────────────────────────────────────────────────

# Tenta instalar winehq-staging com um codename específico.
# Retorna 0 se instalado com sucesso, 1 caso contrário.
try_winehq_suite() {
    local suite="$1"

    echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/winehq.gpg] \
https://dl.winehq.org/wine-builds/ubuntu/ $suite main" \
        > /etc/apt/sources.list.d/winehq.list

    # Atualiza ignorando erros de outros repos (PPAs sem suporte ao codename atual)
    apt-get update -qq 2>/dev/null || true

    if ! apt-cache show winehq-staging &>/dev/null 2>&1; then
        return 1
    fi

    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        --install-recommends winehq-staging >> "$LOG_FILE" 2>&1
}

install_wine() {
    step "Instalando Wine"

    if dpkg -s winehq-staging &>/dev/null 2>&1 || dpkg -s wine &>/dev/null 2>&1; then
        warn "Wine já instalado"; return 0
    fi

    # i386 obrigatório para Wine 32-bit (já habilitado na Fase 5)
    if ! dpkg --print-foreign-architectures | grep -q i386; then
        dpkg --add-architecture i386
        apt-get update -qq >> "$LOG_FILE" 2>&1
    fi

    info "Configurando chave WineHQ..."
    curl -fsSL https://dl.winehq.org/wine-builds/winehq.key -o /tmp/winehq.key >> "$LOG_FILE" 2>&1
    gpg --dearmor < /tmp/winehq.key > /usr/share/keyrings/winehq.gpg 2>> "$LOG_FILE"
    rm -f /tmp/winehq.key

    local codename
    codename=$(lsb_release -cs)

    info "Tentando WineHQ para Ubuntu $codename..."
    if try_winehq_suite "$codename"; then
        ok "Wine Staging instalado (WineHQ $codename)"
        return 0
    fi

    warn "WineHQ não suporta $codename — tentando noble (24.04)..."
    if try_winehq_suite "noble"; then
        ok "Wine Staging instalado (WineHQ noble)"
        return 0
    fi

    warn "WineHQ indisponível — instalando Wine do repositório Ubuntu..."
    rm -f /etc/apt/sources.list.d/winehq.list
    apt-get update -qq 2>/dev/null || true
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq wine wine64 >> "$LOG_FILE" 2>&1 \
        && ok "Wine instalado (Ubuntu repos)" \
        || warn "Falha ao instalar Wine — continuando"
}

# ─── Winetricks ───────────────────────────────────────────────────────────────

install_winetricks() {
    step "Instalando Winetricks"

    # Sempre baixa a versão mais recente do GitHub (repos Ubuntu ficam desatualizados)
    info "Baixando Winetricks (latest)..."
    curl -fsSL \
        https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
        -o /usr/local/bin/winetricks >> "$LOG_FILE" 2>&1
    chmod +x /usr/local/bin/winetricks

    # Dependências necessárias para Winetricks funcionar
    local deps=(cabextract unzip p7zip-full wget curl)
    local to_install=()
    for pkg in "${deps[@]}"; do
        dpkg -s "$pkg" &>/dev/null 2>&1 || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${to_install[@]}" >> "$LOG_FILE" 2>&1
    fi

    ok "Winetricks $(winetricks --version 2>/dev/null | head -1) instalado"
}

# ─── Bottles ──────────────────────────────────────────────────────────────────

install_bottles() {
    step "Instalando Bottles (gerenciador de ambientes Wine)"

    if flatpak list --app 2>/dev/null | grep -q "com.usebottles.bottles"; then
        warn "Bottles já instalado"; return 0
    fi

    info "Instalando Bottles via Flatpak..."
    flatpak install -y --noninteractive flathub com.usebottles.bottles >> "$LOG_FILE" 2>&1 \
        && ok "Bottles instalado" \
        || warn "Falha ao instalar Bottles — continuando"
}

# ─── Resumo ───────────────────────────────────────────────────────────────────

print_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║   Módulo 06-wine concluído com êxito!        ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Wine:${NC}       $(wine --version 2>/dev/null || echo 'instalado')"
    echo -e "  ${BOLD}Winetricks:${NC} $(winetricks --version 2>/dev/null | head -1 || echo 'instalado')"
    echo -e "  ${BOLD}Bottles:${NC}    Flatpak (gerenciador visual de prefixos Wine)"
    echo ""
    echo -e "  ${YELLOW}Use Bottles para criar ambientes Wine isolados.${NC}"
    echo -e "  ${YELLOW}Use Winetricks para instalar DLLs e runtimes Windows.${NC}"
    echo ""
    log "Módulo 06-wine finalizado com sucesso"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║   Tchesco OS — Módulo 06: Wine                ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    init_log
    check_root
    get_real_user
    install_wine
    install_winetricks
    install_bottles
    print_summary
}

main "$@"
