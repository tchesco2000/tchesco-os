#!/usr/bin/env bash
# Tchesco OS — Orquestrador principal de instalação
# Executa todos os módulos em ordem, com timing e resumo final

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
LOG_FILE="/var/log/tchesco-install.log"
START_TIME=$(date +%s)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [orquestrador] $*" >> "$LOG_FILE"; }
info() { echo -e "${CYAN}${BOLD}[TCHESCO]${NC} $*"; log "INFO: $*"; }
ok()   { echo -e "${GREEN}${BOLD}[OK]${NC} $*"; log "OK: $*"; }
warn() { echo -e "${YELLOW}${BOLD}[AVISO]${NC} $*"; log "WARN: $*"; }
die()  { echo -e "${RED}${BOLD}[ERRO]${NC} $*" >&2; log "ERRO: $*"; exit 1; }

check_root()        { [[ $EUID -eq 0 ]] || die "Execute como root: sudo $0"; }
check_modules_dir() { [[ -d "$MODULES_DIR" ]] || die "Diretório de módulos não encontrado: $MODULES_DIR"; }

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

elapsed_since() {
    local since="$1"
    local now; now=$(date +%s)
    local s=$(( now - since ))
    printf "%dm %02ds" $(( s / 60 )) $(( s % 60 ))
}

# ─── Resultados por módulo ────────────────────────────────────────────────────

declare -a MODULE_NAMES=()
declare -a MODULE_TIMES=()
declare -a MODULE_STATUS=()

run_module() {
    local module_file="$1"
    local label="$2"
    local module_start; module_start=$(date +%s)

    echo ""
    echo -e "${BOLD}┌─────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}│  $label${NC}"
    echo -e "${BOLD}└─────────────────────────────────────────────┘${NC}"

    if [[ ! -f "$module_file" ]]; then
        warn "Módulo não encontrado: $module_file — pulando"
        MODULE_NAMES+=("$label"); MODULE_TIMES+=("—"); MODULE_STATUS+=("SKIP")
        return 0
    fi

    [[ -x "$module_file" ]] || chmod +x "$module_file"
    log "Iniciando: $label"

    local status="OK"
    if ! bash "$module_file"; then
        status="ERRO"
        warn "Módulo $label terminou com erro — continuando"
    fi

    local elapsed; elapsed=$(elapsed_since "$module_start")
    MODULE_NAMES+=("$label")
    MODULE_TIMES+=("$elapsed")
    MODULE_STATUS+=("$status")

    log "Módulo $label: $status ($elapsed)"
}

# ─── Resumo final ─────────────────────────────────────────────────────────────

print_summary() {
    local total_elapsed; total_elapsed=$(elapsed_since "$START_TIME")

    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║        Tchesco OS — Instalação concluída!        ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Módulo                          Tempo     Status${NC}"
    echo -e "  ──────────────────────────────────────────────────"

    local all_ok=true
    for i in "${!MODULE_NAMES[@]}"; do
        local name="${MODULE_NAMES[$i]}"
        local time="${MODULE_TIMES[$i]}"
        local st="${MODULE_STATUS[$i]}"
        local color="${GREEN}"
        [[ "$st" == "ERRO" ]] && color="${RED}" && all_ok=false
        [[ "$st" == "SKIP" ]] && color="${YELLOW}"
        printf "  %-32s %-10s %b%s%b\n" "$name" "$time" "$color${BOLD}" "$st" "$NC"
    done

    echo -e "  ──────────────────────────────────────────────────"
    echo -e "  ${BOLD}Tempo total:${NC} $total_elapsed"
    echo ""

    if $all_ok; then
        echo -e "  ${GREEN}${BOLD}Todos os módulos concluídos com sucesso.${NC}"
    else
        echo -e "  ${YELLOW}${BOLD}Alguns módulos tiveram erros. Verifique: $LOG_FILE${NC}"
    fi

    echo ""
    echo -e "  ${YELLOW}Reinicie o sistema para aplicar todas as configurações.${NC}"
    echo ""
    log "Instalação concluída. Tempo total: $total_elapsed"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║                                          ║${NC}"
    echo -e "${CYAN}${BOLD}║        TCHESCO OS — INSTALADOR           ║${NC}"
    echo -e "${CYAN}${BOLD}║               v1.0                       ║${NC}"
    echo -e "${CYAN}${BOLD}║                                          ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${NC}"
    echo ""

    check_root
    check_modules_dir
    init_log

    info "Log: $LOG_FILE"

    run_module "$MODULES_DIR/01-base.sh"       "Fase 2 — Base"
    run_module "$MODULES_DIR/02-theme.sh"      "Fase 3 — Visual macOS"
    run_module "$MODULES_DIR/02b-i18n.sh"      "Fase 3.5 — Idiomas"
    run_module "$MODULES_DIR/03-dev.sh"        "Fase 4 — Desenvolvimento"
    run_module "$MODULES_DIR/04-gaming.sh"     "Fase 5 — Jogos"
    run_module "$MODULES_DIR/05-office.sh"     "Fase 6 — Office"
    run_module "$MODULES_DIR/06-wine.sh"       "Fase 7 — Wine"
    run_module "$MODULES_DIR/07-identity.sh"   "Fase 9 — Identidade"

    print_summary
}

main "$@"
