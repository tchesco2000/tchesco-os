#!/usr/bin/env bash
# Módulo 01 — Base do sistema
# Fase 2 do roadmap: atualização, PPAs, utilitários, timezone e locale

set -euo pipefail

# ─── Constantes ───────────────────────────────────────────────────────────────

LOG_FILE="/var/log/tchesco-install.log"
TIMEZONE="America/Sao_Paulo"
LOCALE="pt_BR.UTF-8"

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
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [01-base] $*"
    echo "$msg" >> "$LOG_FILE"
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

# ─── Verificações iniciais ────────────────────────────────────────────────────

check_root() {
    [[ $EUID -eq 0 ]] || die "Este script precisa ser executado como root. Use: sudo $0"
}

check_ubuntu() {
    if [[ ! -f /etc/os-release ]]; then
        die "Não foi possível identificar o sistema operacional."
    fi
    # shellcheck source=/dev/null
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        die "Este script é para Ubuntu/Kubuntu. Sistema detectado: $ID"
    fi
    ok "Sistema: $PRETTY_NAME"
}

check_internet() {
    info "Verificando conexão com a internet..."
    if ! ping -c 1 -W 5 archive.ubuntu.com &>/dev/null; then
        die "Sem conexão com a internet. Verifique sua rede e tente novamente."
    fi
    ok "Conexão OK"
}

init_log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    log "════════════════════════════════════"
    log "Iniciando módulo 01-base"
    log "════════════════════════════════════"
}

# ─── Funções principais ───────────────────────────────────────────────────────

cleanup_broken_ppas() {
    # Remove PPAs inválidos antes de qualquer apt update para evitar falha com código 100.
    # Necessário porque add-apt-repository não valida disponibilidade antes de adicionar.
    if ls /etc/apt/sources.list.d/*kisak* &>/dev/null 2>&1; then
        warn "Removendo entrada inválida do kisak-mesa (sem suporte para esta versão do Ubuntu)..."
        rm -f /etc/apt/sources.list.d/*kisak* 2>/dev/null || true
        log "Entrada kisak-mesa removida"
    fi
}

update_system() {
    step "Atualizando o sistema"

    info "Configurando apt para modo não-interativo..."
    export DEBIAN_FRONTEND=noninteractive

    info "Atualizando lista de pacotes..."
    apt-get update -qq >> "$LOG_FILE" 2>&1

    info "Aplicando atualizações disponíveis..."
    apt-get upgrade -y -qq \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        >> "$LOG_FILE" 2>&1

    info "Removendo pacotes desnecessários..."
    apt-get autoremove -y -qq >> "$LOG_FILE" 2>&1
    apt-get autoclean -qq >> "$LOG_FILE" 2>&1

    ok "Sistema atualizado"
}

add_ppas() {
    step "Adicionando PPAs"

    # Instala add-apt-repository se não tiver (idempotente)
    if ! command -v add-apt-repository &>/dev/null; then
        info "Instalando software-properties-common..."
        apt-get install -y -qq software-properties-common >> "$LOG_FILE" 2>&1
    fi

    # NOTA: PPA kisak-mesa (drivers Mesa recentes para AMD/Intel) foi movido para
    # 04-gaming.sh, onde faz mais sentido semanticamente. Antes de ativá-lo,
    # verificar se já tem suporte para Ubuntu 26.04 (Resolute) em:
    # https://launchpad.net/~kisak/+archive/ubuntu/kisak-mesa

    # Remove entrada quebrada do kisak-mesa caso tenha sobrado de tentativa anterior
    if grep -rq "kisak-mesa" /etc/apt/sources.list.d/ 2>/dev/null; then
        warn "Removendo entrada antiga do kisak-mesa (sem suporte para esta versão)..."
        rm -f /etc/apt/sources.list.d/*kisak* 2>/dev/null || true
        log "Entrada kisak-mesa removida de sources.list.d"
    fi

    info "Atualizando lista de pacotes..."
    apt-get update -qq >> "$LOG_FILE" 2>&1

    ok "PPAs configurados"
}

install_base_packages() {
    step "Instalando utilitários base"

    local packages=(
        # Ferramentas essenciais de build
        build-essential
        cmake
        pkg-config

        # Controle de versão e rede
        git
        git-lfs
        curl
        wget

        # Monitoramento e diagnóstico
        htop
        btop
        fastfetch
        tree
        ncdu
        lsof
        iotop

        # Utilitários de arquivo
        zip
        unzip
        p7zip-full
        rsync

        # Ferramentas de sistema
        software-properties-common
        apt-transport-https
        ca-certificates
        gnupg
        lsb-release

        # Terminal
        bash-completion
        tmux
        vim

        # Fontes base
        fonts-liberation
        fonts-noto
        fonts-noto-color-emoji
        fonts-firacode
    )

    local to_install=()

    for pkg in "${packages[@]}"; do
        if dpkg -s "$pkg" &>/dev/null 2>&1; then
            warn "$pkg já instalado, pulando"
        else
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        ok "Todos os pacotes base já estão instalados"
        return 0
    fi

    info "Instalando ${#to_install[@]} pacote(s): ${to_install[*]}"
    apt-get install -y -qq "${to_install[@]}" >> "$LOG_FILE" 2>&1

    ok "Utilitários base instalados"
}

configure_timezone() {
    step "Configurando timezone"

    local current_tz
    current_tz=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo "desconhecido")

    if [[ "$current_tz" == "$TIMEZONE" ]]; then
        ok "Timezone já configurado para $TIMEZONE"
        return 0
    fi

    info "Configurando timezone para $TIMEZONE..."
    timedatectl set-timezone "$TIMEZONE" >> "$LOG_FILE" 2>&1

    # Ativa NTP para sincronização automática
    timedatectl set-ntp true >> "$LOG_FILE" 2>&1

    ok "Timezone: $TIMEZONE"
}

configure_locale() {
    step "Configurando locale"

    # Garante que o pacote de locale está instalado
    if ! dpkg -s locales &>/dev/null 2>&1; then
        info "Instalando pacote locales..."
        apt-get install -y -qq locales >> "$LOG_FILE" 2>&1
    fi

    # Garante que pt_BR.UTF-8 está gerado
    if ! locale -a 2>/dev/null | grep -q "pt_BR.utf8"; then
        info "Gerando locale $LOCALE..."
        locale-gen "$LOCALE" >> "$LOG_FILE" 2>&1
    else
        warn "Locale $LOCALE já gerado"
    fi

    # Define como padrão do sistema
    local current_lang
    current_lang=$(locale 2>/dev/null | grep "^LANG=" | cut -d= -f2 | tr -d '"' || echo "")

    if [[ "$current_lang" == "$LOCALE" ]]; then
        ok "Locale já configurado para $LOCALE"
        return 0
    fi

    info "Definindo $LOCALE como locale padrão..."
    update-locale LANG="$LOCALE" LC_ALL="$LOCALE" >> "$LOG_FILE" 2>&1

    # Instala pacotes de idioma português
    local lang_packages=(
        language-pack-pt
        language-pack-pt-base
        language-pack-gnome-pt
        language-pack-gnome-pt-base
    )

    local to_install=()
    for pkg in "${lang_packages[@]}"; do
        dpkg -s "$pkg" &>/dev/null 2>&1 || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Instalando pacotes de idioma PT..."
        apt-get install -y -qq "${to_install[@]}" >> "$LOG_FILE" 2>&1
    fi

    ok "Locale: $LOCALE"
}

print_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║   Módulo 01-base concluído com êxito ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Timezone:${NC}  $TIMEZONE"
    echo -e "  ${BOLD}Locale:${NC}    $LOCALE"
    echo -e "  ${BOLD}Log:${NC}       $LOG_FILE"
    echo ""
    log "Módulo 01-base finalizado com sucesso"
}

# ─── Execução ─────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║   Tchesco OS — Módulo 01: Base          ║${NC}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════╝${NC}"
    echo ""

    init_log
    check_root
    check_ubuntu
    check_internet
    cleanup_broken_ppas
    update_system
    add_ppas
    install_base_packages
    configure_timezone
    configure_locale
    print_summary
}

main "$@"
