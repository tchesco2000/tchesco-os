#!/usr/bin/env bash
# Módulo 03 — Pilar Desenvolvimento
# Fase 4 do roadmap: VS Code, Docker, Node.js, Python, Rust, Go, GitHub CLI, bancos

set -euo pipefail

LOG_FILE="/var/log/tchesco-install.log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [03-dev] $*" >> "$LOG_FILE"; }
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
    log "Iniciando módulo 03-dev"
    log "════════════════════════════════════"
}

# ─── VS Code ──────────────────────────────────────────────────────────────────

install_vscode() {
    step "Instalando VS Code"

    if dpkg -s code &>/dev/null 2>&1; then
        warn "VS Code já instalado"; return 0
    fi

    info "Adicionando repositório Microsoft..."
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
        gpg --dearmor -o /usr/share/keyrings/microsoft.gpg >> "$LOG_FILE" 2>&1

    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
        > /etc/apt/sources.list.d/vscode.list

    apt-get update -qq >> "$LOG_FILE" 2>&1
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq code >> "$LOG_FILE" 2>&1
    ok "VS Code instalado"
}

# ─── Pacotes apt diretos ──────────────────────────────────────────────────────

install_apt_packages() {
    step "Instalando ferramentas de desenvolvimento"

    local packages=(
        # Python
        python3-pip
        python3-venv
        python3-dev

        # Go
        golang-go

        # Editores terminal
        neovim

        # Git e controle de versão
        gh
        gitg

        # Docker
        docker.io
        docker-compose-v2

        # Containers
        podman
        distrobox

        # Bancos de dados (clientes)
        postgresql-client
        mysql-client
        redis-tools
        sqlite3

        # Rede e diagnóstico
        net-tools
        nmap
        traceroute
        openssh-server

        # Java
        default-jdk
    )

    local to_install=()
    for pkg in "${packages[@]}"; do
        dpkg -s "$pkg" &>/dev/null 2>&1 && warn "$pkg já instalado, pulando" || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Instalando ${#to_install[@]} pacote(s)..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${to_install[@]}" >> "$LOG_FILE" 2>&1
    fi

    # Adiciona usuário ao grupo docker
    usermod -aG docker "$REAL_USER" >> "$LOG_FILE" 2>&1
    systemctl enable docker >> "$LOG_FILE" 2>&1

    ok "Ferramentas instaladas"
}

# ─── Node.js via nvm ──────────────────────────────────────────────────────────

install_nvm() {
    step "Instalando Node.js via nvm"

    local nvm_dir="$REAL_HOME/.nvm"

    if [[ -d "$nvm_dir" ]]; then
        warn "nvm já instalado em $nvm_dir"; return 0
    fi

    info "Instalando nvm..."
    as_user bash -c 'curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash' \
        >> "$LOG_FILE" 2>&1

    # Adiciona nvm ao .bashrc se ainda não está
    if ! grep -q "NVM_DIR" "$REAL_HOME/.bashrc" 2>/dev/null; then
        cat >> "$REAL_HOME/.bashrc" << 'EOF'

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
        chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.bashrc"
    fi

    # Instala Node.js LTS
    info "Instalando Node.js LTS..."
    as_user bash -c "source $REAL_HOME/.nvm/nvm.sh && nvm install --lts && nvm use --lts" \
        >> "$LOG_FILE" 2>&1

    ok "Node.js LTS instalado via nvm"
}

# ─── Rust via rustup ──────────────────────────────────────────────────────────

install_rust() {
    step "Instalando Rust via rustup"

    if [[ -f "$REAL_HOME/.cargo/bin/rustc" ]]; then
        warn "Rust já instalado"; return 0
    fi

    info "Instalando rustup..."
    as_user bash -c 'curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path' \
        >> "$LOG_FILE" 2>&1

    # Adiciona cargo ao PATH no .bashrc
    if ! grep -q "cargo" "$REAL_HOME/.bashrc" 2>/dev/null; then
        echo -e '\n# Rust\nexport PATH="$HOME/.cargo/bin:$PATH"' >> "$REAL_HOME/.bashrc"
        chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.bashrc"
    fi

    ok "Rust instalado"
}

# ─── DBeaver CE ───────────────────────────────────────────────────────────────

install_dbeaver() {
    step "Instalando DBeaver CE"

    if dpkg -s dbeaver-ce &>/dev/null 2>&1; then
        warn "DBeaver já instalado"; return 0
    fi

    info "Adicionando repositório DBeaver..."
    curl -fsSL https://dbeaver.io/debs/dbeaver.gpg.key | \
        gpg --dearmor -o /usr/share/keyrings/dbeaver.gpg >> "$LOG_FILE" 2>&1

    echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" \
        > /etc/apt/sources.list.d/dbeaver.list

    apt-get update -qq >> "$LOG_FILE" 2>&1
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq dbeaver-ce >> "$LOG_FILE" 2>&1
    ok "DBeaver CE instalado"
}

# ─── Resumo ───────────────────────────────────────────────────────────────────

print_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║   Módulo 03-dev concluído com êxito!       ║${NC}"
    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Editores:${NC}   VS Code, Neovim"
    echo -e "  ${BOLD}Linguagens:${NC} Node.js LTS (nvm), Python 3, Go, Rust, Java"
    echo -e "  ${BOLD}Containers:${NC} Docker, Docker Compose, Podman, Distrobox"
    echo -e "  ${BOLD}Git:${NC}        Git, GitHub CLI (gh), Gitg"
    echo -e "  ${BOLD}Bancos:${NC}     PostgreSQL client, MySQL client, Redis, SQLite, DBeaver"
    echo -e "  ${BOLD}Rede:${NC}       nmap, net-tools, traceroute, SSH server"
    echo ""
    echo -e "  ${YELLOW}Faça logout para ativar o grupo docker sem sudo.${NC}"
    echo ""
    log "Módulo 03-dev finalizado com sucesso"
}

main() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║   Tchesco OS — Módulo 03: Desenvolvimento     ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    init_log
    check_root
    get_real_user
    install_vscode
    install_apt_packages
    install_nvm
    install_rust
    install_dbeaver
    print_summary
}

main "$@"
