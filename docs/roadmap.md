# Roadmap do Tchesco OS

## Visão geral

Desenvolvimento estimado em **25-40 horas** de trabalho efetivo, distribuídas em algumas semanas de fins de semana.

## Princípios guia

1. **Make it work, make it right, make it fast** — primeiro funcionar, depois perfeito, depois rápido
2. **MVP antes de features** — versão mínima viável distribuível antes de qualquer refinamento
3. **Testar em VM sempre** — nada vai pra hardware real sem passar em VM
4. **Documentar enquanto constrói** — docs junto do código, não depois

## Fases

### Fase 0 — Preparação do ambiente (1-2 horas)

Objetivo: ambiente de desenvolvimento pronto.

- [ ] Instalar VirtualBox no Windows
- [ ] Baixar ISO Kubuntu 26.04 LTS
- [ ] Configurar Claude Code no WSL Ubuntu
- [ ] Criar repositório `tchesco-os` no GitHub
- [ ] Clonar repo no WSL
- [ ] Estrutura inicial de pastas
- [ ] Primeiro commit: README + docs

### Fase 1 — VM base funcionando (30 min)

Objetivo: Kubuntu limpo rodando em VM.

- [ ] Criar VM no VirtualBox (4GB RAM, 40GB disco, 2 CPUs)
- [ ] Instalar Kubuntu 26.04 (instalação padrão)
- [ ] Validar boot e KDE Plasma 6
- [ ] Instalar Guest Additions
- [ ] Snapshot "kubuntu-limpo" (ponto de retorno)

### Fase 2 — Script v0.1: fundação (2-4 horas)

Objetivo: script que prepara o terreno para customização.

- [ ] `scripts/modules/01-base.sh`
  - Atualização completa do sistema
  - Adicionar PPAs necessários
  - Instalar utilitários base
  - Configurar timezone e locale
- [ ] Testar na VM
- [ ] Ajustar erros
- [ ] Commit: "feat: script base v0.1"

### Fase 3 — Script v0.2: identidade visual (3-5 horas)

Objetivo: KDE com cara de macOS.

- [ ] `scripts/modules/02-theme.sh`
  - Clonar e instalar WhiteSur GTK theme
  - Instalar WhiteSur KDE theme
  - Instalar WhiteSur icons
  - Instalar WhiteSur cursors
  - Configurar painel superior (menu global)
  - Instalar e configurar Latte Dock
  - Aplicar wallpaper Tchesco OS
  - Configurar Plymouth (boot splash)
- [ ] Testar troca de tema
- [ ] Validar em idiomas diferentes
- [ ] Commit: "feat: tema macOS aplicado"

### Fase 3.5 — Internacionalização (2-3 horas)

Objetivo: sistema multi-idioma completo.

- [ ] `scripts/modules/02b-i18n.sh`
  - Instalar todos os `language-pack-*`
  - Instalar Noto Fonts completo
  - Configurar fcitx5 como IM padrão
  - Habilitar layouts de teclado múltiplos
  - Configurar `pt_BR.UTF-8` como padrão
- [ ] Testar trocar idioma para inglês e voltar
- [ ] Testar input de japonês (fcitx5 + mozc)
- [ ] Commit: "feat: suporte multi-idioma"

### Fase 4 — Script v0.3: Pilar Desenvolvimento (2-3 horas)

Objetivo: ambiente dev completo.

- [ ] `scripts/modules/03-dev.sh`
  - Instalar VS Code (repo Microsoft)
  - Git, Git LFS, GitHub CLI
  - Docker + Docker Compose
  - Podman + Distrobox
  - Node.js via nvm
  - Python com pip e venv
  - Rust via rustup
  - Go via apt
  - DBeaver CE
  - Clientes PostgreSQL, MySQL, Redis
- [ ] Testar clonar um repo e rodar
- [ ] Testar `docker run hello-world`
- [ ] Commit: "feat: pilar desenvolvimento"

### Fase 5 — Script v0.4: Pilar Jogos (2-3 horas)

Objetivo: gaming funcional.

- [ ] `scripts/modules/04-gaming.sh`
  - `ubuntu-drivers autoinstall` para GPU
  - Habilitar i386 (32-bit)
  - Vulkan drivers (64 e 32 bits)
  - Steam
  - Lutris
  - Heroic (Flatpak)
  - GameMode + MangoHud + GOverlay
  - ProtonUp-Qt
  - CoreCtrl
- [ ] Testar instalação em VM (driver virtualizado)
- [ ] Validar que Steam abre
- [ ] Commit: "feat: pilar jogos"

### Fase 6 — Script v0.5: Pilar Office (2-3 horas)

Objetivo: produtividade do usuário comum.

- [ ] `scripts/modules/05-office.sh`
  - LibreOffice completo com integração KDE
  - OnlyOffice (repo oficial)
  - Firefox + Thunderbird
  - VLC, MPV
  - GIMP, Inkscape, Krita
  - Kdenlive
  - OBS Studio
  - Spotify (Flatpak)
  - Telegram, Discord (Flatpak)
  - CUPS + SANE + Simple Scan
  - Timeshift
- [ ] Testar abrir LibreOffice em PT-BR
- [ ] Testar imprimir PDF (impressora virtual)
- [ ] Commit: "feat: pilar office"

### Fase 7 — Script v0.6: Compatibilidade Windows (2 horas)

Objetivo: rodar .exe.

- [ ] `scripts/modules/06-wine.sh`
  - Wine Staging
  - Winetricks
  - Bottles (Flatpak)
  - ProtonUp-Qt
- [ ] Testar Bottles criando um prefixo
- [ ] Testar rodar um .exe simples (7-Zip portable, por exemplo)
- [ ] Commit: "feat: compatibilidade Windows"

### Fase 8 — Consolidação e testes (4-6 horas)

Objetivo: script único robusto e testado.

- [ ] Criar `scripts/tchesco-install.sh` que orquestra todos os módulos
- [ ] Adicionar tratamento de erro em cada módulo
- [ ] Adicionar logs em `/var/log/tchesco-install.log`
- [ ] Testar instalação limpa completa na VM
- [ ] Medir tempo total de instalação
- [ ] Identificar e corrigir gargalos
- [ ] Commit: "feat: script único consolidado"

### Fase 9 — Identidade do Tchesco OS (1-2 horas)

Objetivo: personalidade visual única.

- [ ] Criar logo Tchesco OS (inicialmente via IA, depois refinar)
- [ ] Wallpaper oficial do Tchesco OS
- [ ] Boot splash com logo
- [ ] Arquivo `/etc/os-release` customizado
- [ ] "Sobre o sistema" mostrando "Tchesco OS 1.0"
- [ ] Commit: "feat: identidade Tchesco OS"

### Fase 10 — Geração da ISO (3-4 horas)

Objetivo: `tchesco-os-1.0.iso` distribuível.

- [ ] Instalar Cubic no Kubuntu
- [ ] Importar ISO Kubuntu 26.04 no Cubic
- [ ] Aplicar script Tchesco dentro do chroot
- [ ] Configurar instalador Calamares com branding Tchesco
- [ ] Gerar ISO final
- [ ] Testar ISO em VM completamente limpa
- [ ] Validar instalação do zero
- [ ] Commit: "release: Tchesco OS 1.0"

### Fase 11 — Distribuição (1 hora)

Objetivo: amigos usando.

- [ ] Fazer hash SHA256 da ISO
- [ ] Upload em servidor (GitHub Releases ou similar)
- [ ] Documentar instruções de instalação
- [ ] Distribuir link pros amigos
- [ ] Colher primeiros feedbacks

## Backlog pós-v1.0

Ideias pra v1.1 ou v2.0:

- Instalador Calamares com branding completo
- Suporte a criptografia de disco por padrão
- Welcome app no primeiro boot
- Central de atualizações customizada
- Repositório próprio Tchesco OS
- Documentação no site
- Versão para Raspberry Pi
- Migração para base Debian (v2.0)
- Otimizações de performance (kernel CachyOS, etc.)
- Tema escuro Tchesco variante

## Métricas de sucesso

- [ ] Boot do zero até desktop em menos de 30 segundos
- [ ] Instalação completa em menos de 20 minutos
- [ ] Roda em VMs com 4GB RAM sem travar
- [ ] Pelo menos 3 amigos instalaram e usam
- [ ] Zero crash na primeira semana de uso
