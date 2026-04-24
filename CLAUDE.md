# CLAUDE.md — Tchesco OS

## Contexto do Projeto

Tchesco OS é uma distribuição Linux baseada em **Kubuntu 26.04 LTS** com visual macOS, automatizada via scripts bash.

- **Repo:** github.com/tchesco2000/tchesco-os
- **Código local:** `/mnt/d/www/ia_documentacao/tchesco_OS`
- **VM de teste:** `192.168.0.24` — user: `suporte`, pass: `tchesco` (SSH liberado)
- **Base:** Ubuntu 26.04 LTS (Resolute Raccoon) + KDE Plasma 6.6.4 + **X11 obrigatório**
- **ISO atual:** `D:\tchesco-os-1.0-amd64.iso` (6.6GB) — gerada com `tchesco-rebuild-v2.sh`
- **Versão:** 1.0

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
│   ├── tchesco-install.sh          # Orquestrador principal (roda como sudo)
│   ├── build-iso.sh                # Build ISO via chroot (base)
│   ├── rebuild-iso-boot.sh         # Rebuild com fixes de boot/Plymouth/welcome
│   ├── tchesco-rebuild-v2.sh       # Rebuild definitivo v2 (usar este)
│   └── modules/
│       ├── 01-base.sh              # ✅ Fase 2 — Base Ubuntu, locale, timezone
│       ├── 02-theme.sh             # ✅ Fase 3 — Visual macOS completo
│       ├── 02b-i18n.sh             # ✅ Fase 3.5 — 11 idiomas + fcitx5
│       ├── 03-dev.sh               # ✅ Fase 4 — VS Code, Docker, Node, Rust, Go
│       ├── 04-gaming.sh            # ✅ Fase 5 — Steam, Lutris, GameMode
│       ├── 05-office.sh            # ✅ Fase 6 — LibreOffice, VLC, OBS
│       ├── 06-wine.sh              # ✅ Fase 7 — Wine Staging, Bottles
│       └── 07-identity.sh          # ✅ Fase 9 — os-release, GRUB, fastfetch
├── setup/
│   ├── calamares/branding/tchesco/ # Branding do instalador Calamares
│   └── welcome/                    # App de boas-vindas Tchesco (PyQt6)
│       ├── tchesco-welcome         # Script Python do welcome
│       ├── tchesco-welcome.desktop
│       ├── tchesco-welcome-autostart.desktop
│       └── install-welcome.sh
├── docs/
│   ├── roadmap.md                  # Status de todas as fases
│   ├── architecture.md             # Decisões técnicas fundamentais
│   ├── packages.md                 # Lista de pacotes por fase
│   └── ...
├── tchesco-logo-pack/              # SVGs e assets visuais
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
- **Causa:** Plasma 6 rejeita Containment desktop com `activityId=` vazio ou plugin errado.
- **Fix:** Detectar Activity ID via DBus ANTES de matar plasmashell, usar `plugin=org.kde.plasma.folder` + `immutability=1`. Função `cleanup_residual_panels()` remove Containments fora do allowlist `{1, 29}`.
- **NÃO usar:** `XUnmapWindow` C helper, `plugin=org.kde.desktopcontainment`, `immutability=2`.

### Bug 7 — Plank não inicia via SSH
- **Causa:** Precisa de `XDG_SESSION_TYPE=x11` e `DESKTOP_SESSION=plasmax11` no env
- **Fix:** `env -i DISPLAY=:0 XDG_SESSION_TYPE=x11 XDG_RUNTIME_DIR=/run/user/1000 XDG_CURRENT_DESKTOP=KDE DESKTOP_SESSION=plasmax11 HOME=/home/suporte USER=suporte PATH=/usr/bin:/bin plank`

### Bug 8 — WhiteSur installs Plymouth with Apple logo
- **Causa:** `02-theme.sh` instala WhiteSur que inclui Plymouth theme com logo Apple.
- **Fix:** No rebuild da ISO, usar `unmkinitramfs` para extrair o initrd, remover arquivos `whitesur*` dentro dele, forçar `Theme=breeze-text` em `etc/plymouth/plymouthd.conf`, reempacotar com cpio+gzip.
- **NÃO usar:** `update-initramfs` no chroot sem bind mounts (não funciona, não regenera o initrd da ISO).

### Bug 9 — plasma-welcome intercepta boot do live
- **Causa:** `plasma-welcome` (pacote KDE) abre automaticamente no primeiro boot, mostrando "Kubuntu".
- **Fix:** `apt-get remove --purge plasma-welcome kubuntu-welcome` no chroot + remover `/etc/xdg/autostart/plasma-welcome.desktop`.

### Bug 10 — ISO live sem tema (desktop Kubuntu padrão)
- **Causa:** KDE configs visuais ficam em `/home/suporte/.config/` na VM de referência mas não são copiadas para o live user `/home/ubuntu/` no squashfs.
- **Fix:** `tchesco-rebuild-v2.sh` copia todos os items KDE críticos do suporte para `/home/ubuntu/` e `/etc/skel/` antes de reempacotar o squashfs.

### Bug 11 — xorriso `curl | gpg --dearmor` quebra pipe
- **Fix:** Fazer download em dois passos separados: `curl -o /tmp/key.gpg` e depois `gpg --dearmor < /tmp/key.gpg > /usr/share/keyrings/...`

### Bug 12 — squashfs >4GB falha no xorriso padrão
- **Fix:** Sempre usar `-iso-level 3 -r -J` no xorriso para suporte a arquivos maiores que 4GB.

### Bug 13 — mksquashfs esgota espaço em /tmp (tmpfs)
- **Causa:** `/tmp` é tmpfs limitado a metade da RAM (~3.9GB).
- **Fix:** Usar `/var/tmp` (ext4) ou criar loop image no D: para workspace de build.

---

## Configuração Visual Validada (Estado atual da VM)

| Elemento | Configuração |
|---|---|
| Top panel (Containment 29) | thickness=44px, floating=1, location=3 |
| Widgets top | kickoff(tchesco-icon-kde.svg) → appmenu → spacer → kickerdash → systemtray → clock |
| Dock | Plank (não Plasma panel): HideMode=1 Intelligent, PressureReveal=true, IconSize=48, Alignment=3 Center, ZoomPercent=150 |
| 8 apps dock | Firefox, Dolphin, Kate, Konsole, VSCode, Spectacle, Settings, Widgets |
| Ícone menu (T) | `tchesco-icon-kde.svg` via `useCustomButtonImage=true` |
| Wallpaper | WhiteSur-dark |
| SDDM | tema breeze + logo horizontal + fundo `#0e1117` |
| Plymouth | breeze-text (sem referência Apple) — corrigido no initrd |
| Firefox | deb Mozilla (não snap), menus internos via policies.json |
| Session | plasmax11 (X11 obrigatório) |
| os-release | NAME="Tchesco OS", PRETTY_NAME="Tchesco OS 1.0" |
| fastfetch | logo T azul/ciano, config em `~/.config/fastfetch/config.jsonc` |

---

## Como Gerar a ISO

```bash
# Rebuild completo (v2) — usar sempre este:
sshpass -p tchesco scp -r scripts/ setup/ suporte@192.168.0.24:~/tchesco-os/
sshpass -p tchesco ssh suporte@192.168.0.24 \
  "echo tchesco | sudo -S bash ~/tchesco-os/scripts/tchesco-rebuild-v2.sh 2>&1"

# ISO de saída: D:\tchesco-os-1.0-amd64.iso
# Tempo estimado: ~35 minutos
# Espaço necessário: 30GB livres no D:
```

### O que o rebuild v2 faz:
1. Cria workspace ext4 de 30GB no D: (evita limitação de disco da VM)
2. Extrai MBR + EFI da ISO Kubuntu original via Python
3. Extrai squashfs do BOOT_ISO (base com todos os pacotes)
4. Remove `plasma-welcome` completamente
5. Copia configs KDE reais do `/home/suporte` para `/home/ubuntu` + `/etc/skel`
6. Instala Tchesco Welcome (PyQt6) + desativa autostart Kubuntu
7. Corrige Plymouth no initrd (remove WhiteSur, força breeze-text)
8. Recomprime squashfs
9. Gera ISO bootável com xorriso (EFI + BIOS + El Torito)

---

## Live Session da ISO

| Item | Valor |
|---|---|
| Usuário live | `ubuntu` |
| Senha live | `tchesco` |
| SDDM | Autologin (sem pedir senha) |
| Welcome screen | Tchesco Welcome (PyQt6) com botões "Experimentar" e "Instalar Tchesco OS" |
| Installer | Calamares com branding `tchesco` |

---

## Como Testar na VM

```bash
# Copiar scripts para VM
sshpass -p tchesco scp -r scripts/ setup/ suporte@192.168.0.24:~/tchesco-os/

# Rodar módulo específico
sshpass -p tchesco ssh suporte@192.168.0.24 \
  "echo tchesco | sudo -S bash ~/tchesco-os/scripts/modules/04-gaming.sh"

# Tirar screenshot da VM
sshpass -p tchesco ssh suporte@192.168.0.24 "DISPLAY=:0 spectacle -b -n -o /tmp/screen.png"
sshpass -p tchesco scp suporte@192.168.0.24:/tmp/screen.png /tmp/

# Rodar orquestrador completo (idempotente)
sshpass -p tchesco ssh suporte@192.168.0.24 \
  "echo tchesco | sudo -S bash ~/tchesco-os/scripts/tchesco-install.sh"
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

## Status das Fases

| Fase | Script | Status |
|---|---|---|
| Fase 0-1 | — | ✅ VM base + ambiente |
| Fase 2 | 01-base.sh | ✅ Base Ubuntu, locale, timezone |
| Fase 3 | 02-theme.sh | ✅ Visual macOS completo |
| Fase 3.5 | 02b-i18n.sh | ✅ 11 idiomas + fcitx5 |
| Fase 4 | 03-dev.sh | ✅ VS Code, Docker, Node, Rust, Go |
| Fase 5 | 04-gaming.sh | ✅ Steam, Lutris, GameMode, MangoHud |
| Fase 6 | 05-office.sh | ✅ LibreOffice, VLC, GIMP, OBS, Spotify |
| Fase 7 | 06-wine.sh | ✅ Wine Staging 11.7, Winetricks, Bottles |
| Fase 8 | consolidação | ✅ Orquestrador completo, idempotência 7/7 OK |
| Fase 9 | 07-identity.sh | ✅ os-release, GRUB, fastfetch Tchesco |
| Fase 10 | tchesco-rebuild-v2.sh | ✅ ISO 6.6GB bootável gerada |
| Fase 11 | distribuição | ⏳ GitHub Releases, SHA256, instruções |

---

## Próximos Passos (v1.1)

- Testar instalação completa com Calamares na VM limpa
- Ajustar live session: usuário `tchesco` / senha `tchesco` (atualmente `ubuntu`/`tchesco`)
- Verificar se tema WhiteSur carrega corretamente no live desktop
- Corrigir nome "Install Kubuntu" que pode aparecer no Calamares
- SHA256 da ISO para distribuição
- GitHub Release com a ISO
- Instruções de instalação no README
