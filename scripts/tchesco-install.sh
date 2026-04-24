#!/usr/bin/env bash
# Tchesco OS — Orquestrador principal de instalação
# Chama todos os módulos em ordem conforme o roadmap

set -euo pipefail

# ─── Constantes ───────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
LOG_FILE="/var/log/tchesco-install.log"
START_TIME=$(date +%s)

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Helpers ──────────────────────────────────────────────────────────────────

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [orquestrador] $*" >> "$LOG_FILE"
}

info() {
    echo -e "${CYAN}${BOLD}[TCHESCO]${NC} $*"
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

# ─── Verificações iniciais ────────────────────────────────────────────────────

check_root() {
    [[ $EUID -eq 0 ]] || die "Execute como root: sudo $0"
}

check_modules_dir() {
    [[ -d "$MODULES_DIR" ]] || die "Diretório de módulos não encontrado: $MODULES_DIR"
}

init_log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    {
        echo ""
        echo "════════════════════════════════════════"
        echo "  Tchesco OS — Instalação iniciada"
        echo "  $(date '+%Y-%m-%d %H:%M:%S')"
        echo "════════════════════════════════════════"
    } >> "$LOG_FILE"
}

# ─── Execução de módulos ──────────────────────────────────────────────────────

run_module() {
    local module_file="$1"
    local module_name
    module_name="$(basename "$module_file")"

    if [[ ! -f "$module_file" ]]; then
        die "Módulo não encontrado: $module_file"
    fi

    if [[ ! -x "$module_file" ]]; then
        chmod +x "$module_file"
    fi

    info "Executando módulo: $module_name"
    log "Iniciando módulo: $module_name"

    if bash "$module_file"; then
        ok "Módulo $module_name concluído"
        log "Módulo $module_name: SUCESSO"
    else
        local exit_code=$?
        die "Módulo $module_name falhou com código $exit_code. Verifique $LOG_FILE"
    fi
}

elapsed_time() {
    local end_time
    end_time=$(date +%s)
    local elapsed=$(( end_time - START_TIME ))
    local minutes=$(( elapsed / 60 ))
    local seconds=$(( elapsed % 60 ))
    echo "${minutes}m ${seconds}s"
}

# ─── Execução principal ───────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║                                          ║${NC}"
    echo -e "${CYAN}${BOLD}║          TCHESCO OS — INSTALADOR         ║${NC}"
    echo -e "${CYAN}${BOLD}║                  v1.0                    ║${NC}"
    echo -e "${CYAN}${BOLD}║                                          ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${NC}"
    echo ""

    check_root
    check_modules_dir
    init_log

    info "Log salvo em: $LOG_FILE"
    echo ""

    # ── Módulos ativos (adicionar aqui conforme cada fase for concluída) ──────
    run_module "$MODULES_DIR/01-base.sh"
    # run_module "$MODULES_DIR/02-theme.sh"      # Fase 3
    # run_module "$MODULES_DIR/02b-i18n.sh"      # Fase 3.5
    # run_module "$MODULES_DIR/03-dev.sh"        # Fase 4
    # run_module "$MODULES_DIR/04-gaming.sh"     # Fase 5
    # run_module "$MODULES_DIR/05-office.sh"     # Fase 6
    # run_module "$MODULES_DIR/06-wine.sh"       # Fase 7

    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║   Instalação do Tchesco OS concluída!    ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Tempo total:${NC} $(elapsed_time)"
    echo -e "  ${BOLD}Log:${NC}         $LOG_FILE"
    echo ""
    echo -e "  Reinicie o sistema para aplicar todas as configurações."
    echo ""

    log "Instalação concluída. Tempo: $(elapsed_time)"
}

main "$@"
