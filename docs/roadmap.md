# Roadmap do Tchesco OS

## Visão geral

Desenvolvimento em fases incrementais, cada uma validada na VM antes de avançar.

## Princípios guia

1. **Make it work, make it right, make it fast** — primeiro funcionar, depois perfeito
2. **MVP antes de features** — versão mínima viável antes de refinamentos
3. **Testar em VM sempre** — nada vai pra hardware real sem passar em VM
4. **Documentar enquanto constrói** — docs junto do código, não depois
5. **Tudo fácil igual macOS** — qualquer decisão de UX segue essa diretriz

---

## Fases

### Fase 0 — Preparação do ambiente ✅ CONCLUÍDA

- [x] VirtualBox no Windows
- [x] ISO Kubuntu 26.04 LTS baixada
- [x] Claude Code no WSL Ubuntu
- [x] Repositório `tchesco-os` criado no GitHub
- [x] Estrutura de pastas e primeiro commit

### Fase 1 — VM base funcionando ✅ CONCLUÍDA

- [x] VM VirtualBox (4GB RAM, 40GB disco, 2 CPUs)
- [x] Kubuntu 26.04 instalado e bootando
- [x] KDE Plasma 6.6.4 validado
- [x] Guest Additions instalados
- [x] SSH funcionando (192.168.0.24, user: suporte)

### Fase 2 — Script v0.1: fundação ✅ CONCLUÍDA

`scripts/modules/01-base.sh`

- [x] Atualização completa do sistema (`apt upgrade`)
- [x] PPAs: git-core, neovim
- [x] Utilitários base: curl, wget, htop, fastfetch, rsync, unzip, etc.
- [x] Timezone: America/Sao_Paulo
- [x] Locale: pt_BR.UTF-8

### Fase 3 — Script v0.2: identidade visual ✅ CONCLUÍDA

`scripts/modules/02-theme.sh`

> Decisões tomadas durante execução (diferem do plano original):
> - **X11 em vez de Wayland** — Plank e Global Menu não funcionam em Wayland
> - **Plank em vez de Latte Dock** — Latte descontinuado no Plasma 6
> - **Firefox deb em vez de snap** — snap não exporta menus DBus para o Global Menu

- [x] WhiteSur GTK + KDE theme + ícones + cursores
- [x] Top panel (44px): kickoff(T) → Global Menu → spacer → busca → bandeja → relógio
- [x] Dock: Plank centralizado, 8 apps, IntelligentHide, zoom 150%
- [x] 8 apps fixos: Firefox, Dolphin, Kate, Konsole, VSCode, Spectacle, Settings, Widgets
- [x] Wallpaper: gradient azul-marinho escuro Tchesco (gerado via PIL)
- [x] Plymouth: breeze-text (sem referência Apple)
- [x] SDDM: breeze + logo Tchesco horizontal + fundo `#0e1117`
- [x] Firefox: deb Mozilla PPA + menus internos via policies.json
- [x] Session: plasmax11 (X11 obrigatório, Wayland oculto)
- [x] Global Menu: appmenu-gtk-module via /etc/profile.d/ + plasma-workspace/env/
- [x] `cleanup_residual_panels()`: remove Containments auto que o Plasma cria (fix "Add Widgets")

### Fase 3.5 — Internacionalização ✅ CONCLUÍDA

`scripts/modules/02b-i18n.sh`

- [x] 11 language-packs (pt-BR, en, es, fr, de, it, zh, ja, ko, ru, ar)
- [x] Noto Fonts completo (inclui CJK, Arabic, Hebrew)
- [x] fcitx5 + mozc (japonês) + chinese-addons (chinês) + hangul (coreano)
- [x] Hunspell: pt-BR, en-US, es, fr, de
- [x] Locale padrão: pt_BR.UTF-8

### Fase 4 — Script v0.3: Pilar Desenvolvimento ✅ CONCLUÍDA

`scripts/modules/03-dev.sh`

- [x] VS Code (repo Microsoft oficial)
- [x] Git, GitHub CLI (gh), Gitg
- [x] Docker + Docker Compose v2 (usuário adicionado ao grupo docker)
- [x] Podman + Distrobox
- [x] Node.js LTS via nvm
- [x] Python 3 + pip + venv + dev
- [x] Rust via rustup
- [x] Go via apt
- [x] DBeaver CE (repo oficial)
- [x] Clientes: PostgreSQL, MySQL, Redis, SQLite
- [x] Neovim, net-tools, nmap, traceroute, SSH server, Java (default-jdk)

---

### Fase 5 — Script v0.4: Pilar Jogos ✅ CONCLUÍDA

`scripts/modules/04-gaming.sh`

> Decisões tomadas durante execução:
> - **Lutris via Flatpak** — PPA não suporta Ubuntu 26.04 "resolute" ainda
> - **MangoHud sem i386** — pacote `mangohud:i386` não disponível no Ubuntu 26.04

- [x] `dpkg --add-architecture i386` (32-bit)
- [x] Drivers GPU: Mesa genérico + `ubuntu-drivers autoinstall` (não-fatal em VM)
- [x] Vulkan: `vulkan-tools`, `libvulkan1`, `libvulkan1:i386`
- [x] Steam (multiverse Ubuntu)
- [x] Lutris (Flatpak — PPA sem suporte a resolute)
- [x] Heroic Games Launcher (Flatpak)
- [x] GameMode (`gamemode`)
- [x] MangoHud 64-bit (`mangohud`)
- [x] GOverlay (Flatpak — configurador MangoHud)
- [x] ProtonUp-Qt (Flatpak — gerencia versões Proton-GE)
- [x] CoreCtrl + polkit rule (controle de GPU sem senha root)
- [x] `gamemode.ini` com perfil `performance`

### Fase 6 — Script v0.5: Pilar Office ✅ CONCLUÍDA

`scripts/modules/05-office.sh`

> Decisões tomadas durante execução:
> - **OnlyOffice via Flatpak** — mais simples que repositório oficial (evita EULA interativa)
> - **OBS via apt** — disponível no Ubuntu 26.04 universe (sem necessidade de Flatpak)

- [x] LibreOffice + l10n-pt-br + help-pt-br + Qt6 (integração KDE)
- [x] Fontes Microsoft (ttf-mscorefonts) + ubuntu-restricted-extras (codecs)
- [x] OnlyOffice Desktop (Flatpak)
- [x] VLC, MPV
- [x] GIMP, Inkscape, Krita
- [x] Kdenlive
- [x] OBS Studio (apt)
- [x] Spotify, Telegram, Discord (Flatpak)
- [x] CUPS + cups-browsed + SANE + Simple Scan + printer-driver-all
- [x] Timeshift (backup)

### Fase 7 — Script v0.6: Compatibilidade Windows ⏳ PRÓXIMA

`scripts/modules/06-wine.sh`

- [ ] Wine Staging (repo WineHQ)
- [ ] Winetricks
- [ ] Bottles (Flatpak)
- [ ] Testar rodar .exe simples

### Fase 8 — Consolidação e testes ⏳

- [ ] Instalação limpa completa na VM (do zero)
- [ ] Medir tempo total de instalação
- [ ] Tratamento de erros em todos os módulos
- [ ] Logs em `/var/log/tchesco-install.log`

### Fase 9 — Identidade do Tchesco OS ⏳

- [ ] `/etc/os-release` customizado (NAME="Tchesco OS")
- [ ] "Sobre o Sistema" mostrando Tchesco OS 1.0
- [ ] Neofetch/fastfetch com logo ASCII Tchesco

### Fase 10 — Geração da ISO ⏳

- [ ] Cubic: importar ISO Kubuntu 26.04
- [ ] Aplicar script Tchesco no chroot
- [ ] Calamares com branding Tchesco
- [ ] Gerar e testar ISO em VM limpa

### Fase 11 — Distribuição ⏳

- [ ] SHA256 da ISO
- [ ] GitHub Releases
- [ ] Instruções de instalação
- [ ] Distribuir para amigos

---

## Backlog pós-v1.0

- Welcome app no primeiro boot
- Tema escuro variante Tchesco
- Repositório próprio
- Site com documentação
- Versão para Raspberry Pi
- Migração para base Debian (v2.0)
- Kernel CachyOS para performance

## Métricas de sucesso

- [ ] Boot do zero até desktop em menos de 30 segundos
- [ ] Instalação completa em menos de 20 minutos
- [ ] Roda em VMs com 4GB RAM sem travar
- [ ] Pelo menos 3 amigos instalaram e usam
