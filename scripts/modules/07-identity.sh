#!/usr/bin/env bash
# Módulo 07 — Identidade Tchesco OS
# Fase 9: os-release, lsb-release, issue, GRUB, fastfetch com logo ASCII

set -euo pipefail

LOG_FILE="/var/log/tchesco-install.log"
TCHESCO_VERSION="1.0"
TCHESCO_GITHUB="https://github.com/tchesco2000/tchesco-os"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [07-identity] $*" >> "$LOG_FILE"; }
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

check_root() { [[ $EUID -eq 0 ]] || die "Execute como root: sudo $0"; }

init_log() {
    mkdir -p "$(dirname "$LOG_FILE")"; touch "$LOG_FILE"
    log "════════════════════════════════════"
    log "Iniciando módulo 07-identity"
    log "════════════════════════════════════"
}

# ─── /etc/os-release ──────────────────────────────────────────────────────────

configure_os_release() {
    step "Configurando /etc/os-release"

    if grep -q '^NAME="Tchesco OS"' /etc/os-release 2>/dev/null; then
        warn "os-release já configurado"; return 0
    fi

    # Backup antes de modificar
    cp /etc/os-release /etc/os-release.ubuntu-original
    log "Backup: /etc/os-release.ubuntu-original"

    # ─ Campos de exibição ─────────────────────────────────────────────────────
    # NÃO TOCAR: ID, ID_LIKE, VERSION_ID, VERSION_CODENAME, UBUNTU_CODENAME
    # Esses campos são usados pelo apt, add-apt-repository e ubuntu-drivers
    sed -i "s|^NAME=.*|NAME=\"Tchesco OS\"|" /etc/os-release
    sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"Tchesco OS ${TCHESCO_VERSION} (baseado em Kubuntu 26.04 LTS)\"|" /etc/os-release
    sed -i "s|^VERSION=.*|VERSION=\"${TCHESCO_VERSION}\"|" /etc/os-release

    # URLs — atualiza se existirem, adiciona se não
    for field in HOME_URL SUPPORT_URL BUG_REPORT_URL; do
        if grep -q "^${field}=" /etc/os-release; then
            sed -i "s|^${field}=.*|${field}=\"${TCHESCO_GITHUB}\"|" /etc/os-release
        else
            echo "${field}=\"${TCHESCO_GITHUB}\"" >> /etc/os-release
        fi
    done

    # Marca de versão Tchesco (não interfere com ferramentas Ubuntu)
    grep -q '^TCHESCO_VERSION=' /etc/os-release || \
        echo "TCHESCO_VERSION=\"${TCHESCO_VERSION}\"" >> /etc/os-release

    ok "/etc/os-release atualizado (ID e VERSION_CODENAME preservados)"
}

# ─── /etc/lsb-release ─────────────────────────────────────────────────────────

configure_lsb_release() {
    step "Configurando /etc/lsb-release"

    if grep -q "^DISTRIB_DESCRIPTION=\"Tchesco OS" /etc/lsb-release 2>/dev/null; then
        warn "lsb-release já configurado"; return 0
    fi

    cp /etc/lsb-release /etc/lsb-release.ubuntu-original

    # NÃO TOCAR: DISTRIB_ID, DISTRIB_RELEASE, DISTRIB_CODENAME
    # add-apt-repository usa DISTRIB_CODENAME para construir URLs de PPA
    sed -i "s|^DISTRIB_DESCRIPTION=.*|DISTRIB_DESCRIPTION=\"Tchesco OS ${TCHESCO_VERSION}\"|" \
        /etc/lsb-release

    ok "/etc/lsb-release atualizado (DISTRIB_CODENAME preservado)"
}

# ─── /etc/issue ───────────────────────────────────────────────────────────────

configure_issue() {
    step "Configurando mensagem de login (/etc/issue)"

    cat > /etc/issue << EOF
Tchesco OS ${TCHESCO_VERSION} — baseado em Kubuntu 26.04 LTS
\n \l

EOF

    cat > /etc/issue.net << EOF
Tchesco OS ${TCHESCO_VERSION} — baseado em Kubuntu 26.04 LTS
EOF

    ok "/etc/issue e /etc/issue.net atualizados"
}

# ─── GRUB ─────────────────────────────────────────────────────────────────────

configure_grub() {
    step "Configurando GRUB"

    if [[ ! -f /etc/default/grub ]]; then
        warn "/etc/default/grub não encontrado — pulando"; return 0
    fi

    cp /etc/default/grub /etc/default/grub.ubuntu-original

    if grep -q '^GRUB_DISTRIBUTOR=' /etc/default/grub; then
        sed -i 's|^GRUB_DISTRIBUTOR=.*|GRUB_DISTRIBUTOR="Tchesco OS"|' /etc/default/grub
    else
        echo 'GRUB_DISTRIBUTOR="Tchesco OS"' >> /etc/default/grub
    fi

    info "Atualizando GRUB (pode levar alguns segundos)..."
    update-grub >> "$LOG_FILE" 2>&1

    ok "GRUB atualizado — menu mostrará 'Tchesco OS'"
}

# ─── fastfetch ────────────────────────────────────────────────────────────────

configure_fastfetch() {
    step "Configurando fastfetch com logo Tchesco"

    if ! command -v fastfetch &>/dev/null; then
        warn "fastfetch não instalado — pulando"; return 0
    fi

    local config_dir="$REAL_HOME/.config/fastfetch"
    local logo_dir="/etc/fastfetch"
    mkdir -p "$config_dir" "$logo_dir"

    # ─ Logo ASCII: "T" estilizado em azul → ciano (23 chars de largura) ───────
    local ESC=$'\033'
    cat > "$logo_dir/tchesco-logo.txt" << EOF
${ESC}[1;34m   ████████████████   ${ESC}[0m
${ESC}[1;34m   ████████████████   ${ESC}[0m
${ESC}[1;34m   ████████████████   ${ESC}[0m
${ESC}[1;34m        ██████        ${ESC}[0m
${ESC}[1;34m        ██████        ${ESC}[0m
${ESC}[1;36m        ██████        ${ESC}[0m
${ESC}[1;36m        ██████        ${ESC}[0m
${ESC}[1;36m        ██████        ${ESC}[0m
${ESC}[1;36m        ██████        ${ESC}[0m
${ESC}[1;36m        ██████        ${ESC}[0m
EOF

    # ─ Config fastfetch ────────────────────────────────────────────────────────
    cat > "$config_dir/config.jsonc" << 'JSONC'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "/etc/fastfetch/tchesco-logo.txt",
        "type": "file",
        "padding": {
            "top": 1,
            "left": 2
        }
    },
    "display": {
        "separator": "  "
    },
    "modules": [
        "title",
        "separator",
        "os",
        "host",
        "kernel",
        "uptime",
        "packages",
        "shell",
        "display",
        "de",
        "wm",
        "theme",
        "icons",
        "font",
        "cursor",
        "terminal",
        "cpu",
        "gpu",
        "memory",
        "disk",
        "separator",
        "colors"
    ]
}
JSONC

    chown -R "$REAL_USER:$REAL_USER" "$config_dir"

    ok "fastfetch configurado — logo Tchesco ativo"
}

# ─── Verificação final ────────────────────────────────────────────────────────

verify_apt_integrity() {
    step "Verificando integridade do apt após mudanças"

    # Garante que apt ainda funciona — lsb_release -cs deve retornar "resolute"
    local codename
    codename=$(lsb_release -cs 2>/dev/null)

    if [[ "$codename" == "resolute" ]]; then
        ok "apt intacto — lsb_release -cs = '$codename'"
    else
        warn "ATENÇÃO: lsb_release -cs retornou '$codename' (esperado: resolute)"
        warn "Restaurando lsb-release original..."
        cp /etc/lsb-release.ubuntu-original /etc/lsb-release
    fi

    # Teste rápido de apt
    if apt-get check >> "$LOG_FILE" 2>&1; then
        ok "apt check OK"
    else
        warn "apt check com aviso — verifique o log"
    fi
}

# ─── Resumo ───────────────────────────────────────────────────────────────────

print_summary() {
    local name; name=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2)
    local pretty; pretty=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'"' -f2)
    local codename; codename=$(lsb_release -cs 2>/dev/null)
    local grub_dist; grub_dist=$(grep '^GRUB_DISTRIBUTOR=' /etc/default/grub 2>/dev/null | cut -d'"' -f2 || echo "—")

    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║   Módulo 07-identity concluído com êxito!    ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}OS Name:${NC}       $name"
    echo -e "  ${BOLD}Pretty Name:${NC}   $pretty"
    echo -e "  ${BOLD}apt codename:${NC}  $codename (preservado ✓)"
    echo -e "  ${BOLD}GRUB:${NC}          $grub_dist"
    echo -e "  ${BOLD}fastfetch:${NC}     logo Tchesco configurado"
    echo ""
    echo -e "  ${YELLOW}Abra 'Configurações do Sistema > Sobre este Sistema'${NC}"
    echo -e "  ${YELLOW}para ver 'Tchesco OS' no KDE.${NC}"
    echo ""
    log "Módulo 07-identity finalizado com sucesso"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║   Tchesco OS — Módulo 07: Identidade          ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    init_log
    check_root
    get_real_user
    configure_os_release
    configure_lsb_release
    configure_issue
    configure_grub
    configure_fastfetch
    verify_apt_integrity
    print_summary
}

main "$@"
