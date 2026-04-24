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

### Fase 7 — Script v0.6: Compatibilidade Windows ✅ CONCLUÍDA

`scripts/modules/06-wine.sh`

> Decisões tomadas durante execução:
> - **WineHQ resolute funciona** — repo suporta Ubuntu 26.04 (ao contrário do Lutris PPA)
> - **curl key separado do gpg** — pipe `curl | gpg --dearmor` quebrava; fix: download em dois passos
> - **apt update com `|| true`** — resiliente a PPAs com erro (ex: Lutris PPA órfão)
> - **Winetricks do GitHub** — versão latest (repos Ubuntu ficam desatualizados)

- [x] Wine Staging 11.7 (WineHQ resolute)
- [x] Winetricks 20260125-next (latest do GitHub)
- [x] Bottles (Flatpak)
- [x] Dependências Winetricks: cabextract, unzip, p7zip-full

### Fase 8 — Consolidação e testes ✅ CONCLUÍDA

> Correções aplicadas:
> - **02-theme.sh**: `|| true` nos 4 scripts WhiteSur (install.sh sai com não-zero mesmo em sucesso)
> - **06-wine.sh**: chave WineHQ em dois passos (curl separado do gpg --dearmor); apt update `|| true`
> - **tchesco-install.sh**: orquestrador com timing por módulo, tabela de resumo, resiliência a erros

- [x] Orquestrador atualizado com Fases 2–7 completas
- [x] Timing por módulo + tabela de resumo colorida
- [x] Teste de idempotência: 7/7 módulos OK em sistema já instalado
- [x] Tempo total em sistema já instalado: **1m 10s**
- [x] Logs em `/var/log/tchesco-install.log`

### Fase 9 — Identidade do Tchesco OS ✅ CONCLUÍDA

`scripts/modules/07-identity.sh`

> Regra crítica aplicada: apenas campos de exibição foram alterados.
> ID=ubuntu, VERSION_CODENAME=resolute e DISTRIB_CODENAME preservados intactos.
> Verificação automática de apt integrity ao final do módulo.

- [x] `/etc/os-release` — NAME, PRETTY_NAME, VERSION, HOME_URL atualizados
- [x] `/etc/lsb-release` — DISTRIB_DESCRIPTION atualizado
- [x] `/etc/issue` e `/etc/issue.net` — banner Tchesco OS 1.0
- [x] GRUB — GRUB_DISTRIBUTOR="Tchesco OS" + update-grub
- [x] fastfetch — logo "T" azul/ciano + config com 20 módulos de info
- [x] KDE "Sobre este Sistema" — automático via os-release (mostra Tchesco OS)
- [x] apt intacto — lsb_release -cs = 'resolute' confirmado

### Fase 10 — Geração da ISO ⚠️ EM REVISÃO

`scripts/tchesco-rebuild-v2.sh` ← script atual (abordagem de patching)
`setup/calamares/branding/tchesco/`
`setup/welcome/` — Tchesco Welcome (PyQt6)

> **v1.0** — ISO 6.6GB gerada e bootável. Visual correto.
> **v1.1** — Fixes aplicados (bugs 14-17), mas visual do live ainda com defeitos (Bug 18).
> **Problema fundamental:** rebuild extrai squashfs de ISO antiga e cola configs por cima — frágil. Dock some, wallpaper errado, serviços KDE com falha.

**ISO v1.0 (funcional):**
- [x] Plymouth corrigido no initrd — `breeze-text`, sem logo Apple
- [x] `plasma-welcome` removido com `apt purge`
- [x] Configs KDE reais copiadas do suporte para live user
- [x] Tchesco Welcome (PyQt6) — "Experimentar" e "Instalar Tchesco OS"
- [x] Calamares branding `tchesco`
- [x] GRUB: "Try or Install Tchesco OS"
- [x] ISO: **6.6GB**, El Torito ✅, EFI + BIOS ✅
- [x] Boot funcional no VirtualBox

**ISO v1.1 (fixes parciais):**
- [x] `welcome.conf` Calamares → "Tchesco OS 1.0" (Bug 14)
- [x] Botão instalar → `pkexec calamares` (Bug 15)
- [x] `plank.desktop` autostart → `env XDG_SESSION_TYPE=x11` (Bug 16 — fix aplicado, dock ainda some por Bug 18)
- [x] `calamares.desktop` → "Instalar Tchesco OS" (Bug 17)
- [ ] Visual live idêntico à VM (bloqueado pelo Bug 18)

**Próximo passo obrigatório (v1.2):** capturar squashfs diretamente da VM com `mksquashfs /` (excluindo `/proc /sys /dev /tmp /run`) e usar como base do rebuild em vez de uma ISO antiga.

### Fase 11 — Distribuição ⏳ AGUARDANDO ISO ESTÁVEL

- [ ] Resolver Bug 18 (squashfs direto da VM) → ISO v1.2 com visual correto
- [ ] Teste de instalação completa em VM limpa com Calamares
- [ ] SHA256 da ISO
- [ ] GitHub Release com ISO anexada
- [ ] README com instruções de instalação
- [ ] Distribuir para amigos para teste

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
