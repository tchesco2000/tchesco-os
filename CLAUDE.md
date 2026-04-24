# CLAUDE.md — Tchesco OS

## Contexto do Projeto

Tchesco OS é uma distribuição Linux baseada em **Kubuntu 26.04 LTS** com visual macOS, automatizada via scripts bash.

- **Repo:** github.com/tchesco2000/tchesco-os
- **Código local:** `/mnt/d/www/ia_documentacao/tchesco_OS`
- **VM de teste:** `192.168.0.24` — user: `suporte`, pass: `tchesco` (SSH liberado)
- **Base:** Ubuntu 26.04 LTS (Resolute Raccoon) + KDE Plasma 6.6.4 + **X11 obrigatório**

---

## Regras Obrigatórias

- **NÃO mexer em nada que já funciona** — cada melhoria quebrada custa horas. Se funciona, não toca sem motivo.
- **Testar na VM SEMPRE** antes de commitar qualquer script de fase nova.
- **Commits após cada fase validada** — nunca commitar script não testado.
- Filosofia de UX: **"tudo fácil igual macOS"** — qualquer decisão de design segue essa diretriz.
- **"Dock"** é o termo correto — nunca "Gerenciador de tarefas" (nome interno KDE).

---

## Estrutura do Projeto

```
tchesco_OS/
├── scripts/
│   ├── tchesco-install.sh       # Orquestrador principal (roda como sudo)
│   └── modules/
│       ├── 01-base.sh           # ✅ Fase 2 — Base Ubuntu, locale, timezone
│       ├── 02-theme.sh          # ✅ Fase 3 — Visual macOS completo
│       ├── 02b-i18n.sh          # ✅ Fase 3.5 — 11 idiomas + fcitx5
│       ├── 03-dev.sh            # ✅ Fase 4 — VS Code, Docker, Node, Rust, Go
│       ├── 04-gaming.sh         # ⏳ Fase 5 — Steam, Lutris, GameMode
│       ├── 05-office.sh         # ⏳ Fase 6 — LibreOffice, VLC, OBS
│       ├── 06-wine.sh           # ⏳ Fase 7 — Wine, Bottles
│       └── ...
├── docs/
│   ├── roadmap.md               # Status de todas as fases
│   ├── architecture.md          # Decisões técnicas fundamentais
│   ├── packages.md              # Lista de pacotes por fase
│   └── ...
├── tchesco-logo-pack/           # SVGs e assets visuais
└── tests/
    └── vm-test-checklist.md
```

---

## Decisão Crítica: X11, não Wayland

**Kubuntu 26.04 vem com Wayland por padrão, mas Tchesco OS usa plasmax11.**

Motivos:
- **Plank dock** só funciona em X11 (`XDG_SESSION_TYPE=x11` obrigatório para iniciar)
- **Global Menu** (GTK_MODULES=appmenu-gtk-module) não funciona em Wayland
- **AutoHide confiável** do Plank em X11 (Wayland tem bugs de hover)

Config SDDM em `/etc/sddm.conf.d/30-tchesco-x11.conf`:
```
[Autologin]
User=suporte
Session=plasmax11
```

---

## Padrão dos Módulos bash

Todo módulo `.sh` segue esta estrutura:

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/tchesco-install.log"
# Cores: RED GREEN YELLOW BLUE CYAN BOLD NC

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [modulo] $*" >> "$LOG_FILE"; }
info() { echo -e "${CYAN}${BOLD}[TCHESCO]${NC} $*"; log "INFO: $*"; }
ok()   { echo -e "${GREEN}${BOLD}[OK]${NC} $*"; log "OK: $*"; }
warn() { echo -e "${YELLOW}${BOLD}[AVISO]${NC} $*"; log "WARN: $*"; }
die()  { echo -e "${RED}${BOLD}[ERRO]${NC} $*" >&2; log "ERRO: $*"; exit 1; }
step() { echo ""; echo -e "${BOLD}━━━ $* ━━━${NC}"; }

get_real_user() {
    REAL_USER="${SUDO_USER:-}"
    [[ -z "$REAL_USER" ]] && REAL_USER=$(getent passwd | awk -F: '$3>=1000&&$3<65534{print $1;exit}')
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
}

as_user() { sudo -u "$REAL_USER" env HOME="$REAL_HOME" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" "$@"; }
check_root() { [[ $EUID -eq 0 ]] || die "Execute como root: sudo $0"; }
```

---

## Bugs Conhecidos e Soluções (NÃO repetir)

### Bug 1 — SVG com filtros Qt-incompatíveis
- **Causa:** `filter="url(#glow)"` com `feGaussianBlur` — Qt não suporta filtros SVG
- **Fix:** Sempre usar `tchesco-icon-kde.svg` (sem filtros) como ícone do sistema

### Bug 2 — Python `~` expande para /root
- **Causa:** scripts rodam como root → `os.path.expanduser("~")` = `/root`
- **Fix:** Passar `REAL_HOME="$REAL_HOME" python3` e usar `os.environ.get("REAL_HOME")`

### Bug 3 — Painéis órfãos via qdbus evaluateScript
- **Fix:** NÃO usar `qdbus evaluateScript`. Escrever diretamente em `plasmashellrc` e `appletsrc`. IDs fixos: Panel 29 (top), Containment 1 (desktop).

### Bug 4 — Firefox snap sem menus
- **Fix:** Remover snap + adicionar repo Mozilla (`packages.mozilla.org`) + instalar deb.

### Bug 5 — GTK_MODULES não chega em apps
- **Fix:** `/etc/profile.d/tchesco-gtk-modules.sh` + `~/.config/plasma-workspace/env/gtk-modules.sh`

### Bug 6 — "Add Widgets" fantasma sobre o Plank
- **Causa:** Plasma 6 rejeita Containment desktop com `activityId=` vazio ou plugin errado, cria outro auto (id 52/49/55) que renderiza o ToolBoxButton sobre o Plank.
- **Fix:** No `configure_top_panel()`: detectar Activity ID via DBus ANTES de matar plasmashell, injetar no `[Containments][1]`, usar `plugin=org.kde.plasma.folder` + `immutability=1`. Matar plasmashell antes de escrever arquivos. Função `cleanup_residual_panels()` remove qualquer Containment/Panel fora do allowlist `{1, 29}`.
- **NÃO usar:** `XUnmapWindow` C helper, daemon xwininfo, `plugin=org.kde.desktopcontainment`, `immutability=2`.

### Bug 7 — Plank não inicia via SSH
- **Causa:** Precisa de `XDG_SESSION_TYPE=x11` e `DESKTOP_SESSION=plasmax11` no env
- **Fix:** `env -i DISPLAY=:0 XDG_SESSION_TYPE=x11 XDG_RUNTIME_DIR=/run/user/1000 XDG_CURRENT_DESKTOP=KDE DESKTOP_SESSION=plasmax11 HOME=/home/suporte USER=suporte PATH=/usr/bin:/bin plank`

---

## Configuração Visual Validada (Estado atual da VM)

| Elemento | Configuração |
|---|---|
| Top panel (Containment 29) | thickness=44px, floating=1, location=3 |
| Widgets top | kickoff(tchesco-icon-kde.svg) → appmenu → spacer → kickerdash → systemtray → clock |
| Dock | Plank (não Plasma panel): HideMode=1 Intelligent, PressureReveal=true, IconSize=48, Alignment=3 Center, ZoomPercent=150 |
| 8 apps dock | Firefox, Dolphin, Kate, Konsole, VSCode, Spectacle, Settings, Widgets |
| Ícone menu (T) | `tchesco-icon-kde.svg` via `useCustomButtonImage=true` |
| Wallpaper | WhiteSur-dark (substituído por gradient Tchesco escuro via PIL) |
| SDDM | tema breeze + logo horizontal + fundo `#0e1117` |
| Plymouth | breeze-text (sem referência Apple) |
| Firefox | deb Mozilla (não snap), menus internos via policies.json |
| Session | plasmax11 (X11 obrigatório) |

---

## Como Testar na VM

```bash
# Copiar script para VM
sshpass -p tchesco scp -r scripts/ suporte@192.168.0.24:~/tchesco-os/

# Rodar módulo específico
sshpass -p tchesco ssh suporte@192.168.0.24 "cd ~/tchesco-os && sudo bash scripts/modules/04-gaming.sh"

# Tirar screenshot da VM
sshpass -p tchesco ssh suporte@192.168.0.24 "DISPLAY=:0 spectacle -b -n -o /tmp/screen.png"
sshpass -p tchesco scp suporte@192.168.0.24:/tmp/screen.png /tmp/
```

---

## Como Iniciar Plank via SSH (para debug)

```bash
sshpass -p tchesco ssh suporte@192.168.0.24 \
  "env -i DISPLAY=:0 XDG_SESSION_TYPE=x11 XDG_RUNTIME_DIR=/run/user/1000 \
   XDG_CURRENT_DESKTOP=KDE XDG_SESSION_DESKTOP=KDE DESKTOP_SESSION=plasmax11 \
   HOME=/home/suporte USER=suporte PATH=/usr/bin:/bin nohup plank >/dev/null 2>&1 & disown"
```

---

## Próximas Fases

| Fase | Script | Status |
|---|---|---|
| Fase 5 | 04-gaming.sh | ⏳ Steam, Lutris, GameMode, MangoHud, ProtonUp-Qt, i386 |
| Fase 6 | 05-office.sh | ⏳ LibreOffice, OnlyOffice, VLC, GIMP, OBS, Timeshift |
| Fase 7 | 06-wine.sh | ⏳ Wine Staging, Winetricks, Bottles |
| Fase 8 | consolidação | ⏳ Testes limpos completos |
| Fase 9 | identidade | ⏳ /etc/os-release, "Sobre o Sistema" |
| Fase 10 | ISO | ⏳ Cubic + Calamares |
| Fase 11 | distribuição | ⏳ GitHub Releases |
