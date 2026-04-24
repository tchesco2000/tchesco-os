# Pacotes do Tchesco OS

Lista organizada por pilar e categoria. Todos disponíveis em repositórios oficiais Ubuntu 26.04 LTS, PPAs confiáveis ou Flatpak.

## Base do sistema

- `ubuntu-desktop-minimal` — base Ubuntu
- `kubuntu-desktop` — KDE Plasma 6
- `linux-image-generic` — kernel 7.0
- `linux-firmware` — firmwares de hardware
- `build-essential` — ferramentas de compilação
- `git`, `curl`, `wget`, `htop`, `neofetch`, `tree`

## Tema e identidade visual

- `plasma-workspace-wallpapers` — wallpapers base
- `latte-dock` — dock estilo macOS
- `plank` — alternativa leve de dock
- `kvantum` — engine de temas Qt
- `papirus-icon-theme` — ícones alternativos
- Temas via GitHub (WhiteSur, McMojave):
  - WhiteSur-gtk-theme
  - WhiteSur-kde
  - WhiteSur-icon-theme
  - WhiteSur-cursors

## Fontes (multi-idioma)

- `fonts-noto` — Noto completo
- `fonts-noto-cjk` — chinês, japonês, coreano
- `fonts-noto-color-emoji` — emojis
- `fonts-inter` — fonte padrão da interface
- `fonts-liberation` — compatibilidade MS Office
- `fonts-firacode` — fonte monospace para dev
- `fonts-jetbrains-mono` — alternativa monospace

## Internacionalização

- `language-pack-*` — todos os idiomas disponíveis
- `libreoffice-l10n-*` — traduções LibreOffice
- `firefox-locale-*` — traduções Firefox
- `thunderbird-locale-*` — traduções Thunderbird
- `fcitx5` — framework de input method
- `fcitx5-mozc` — japonês
- `fcitx5-chinese-addons` — chinês
- `fcitx5-hangul` — coreano
- `hunspell-*` — corretores ortográficos

## Pilar 1: Desenvolvimento

### Editores e IDEs
- `code` — Visual Studio Code (via repositório Microsoft)
- `vim`, `neovim` — editores de terminal
- `geany` — IDE leve alternativa

### Linguagens e runtimes
- `python3`, `python3-pip`, `python3-venv`
- `nodejs`, `npm` (via nvm para versões flexíveis)
- `golang-go` — Go
- `rustc`, `cargo` (via rustup)
- `default-jdk` — Java
- `php`, `php-cli`
- `ruby`, `ruby-dev`

### Containers e virtualização
- `docker.io`, `docker-compose-v2`
- `podman`
- `distrobox` — rodar qualquer distro em container
- `qemu-kvm`, `virt-manager` — virtualização

### Controle de versão
- `git`, `git-lfs`
- `gh` — GitHub CLI
- `gitg` — interface gráfica git

### Banco de dados (clientes)
- `postgresql-client`
- `mysql-client`
- `redis-tools`
- `sqlite3`
- `dbeaver-ce` — GUI multi-banco

### Ferramentas de rede
- `net-tools`, `nmap`, `traceroute`
- `openssh-client`, `openssh-server`
- `wireshark` (opcional)

## Pilar 2: Jogos

### Drivers de vídeo
- `nvidia-driver-XXX` ou `nvidia-open` (detectado pelo `ubuntu-drivers`)
- `mesa-vulkan-drivers`, `mesa-vulkan-drivers:i386`
- `libvulkan1`, `libvulkan1:i386`
- `vulkan-tools`

### Plataformas de jogo
- `steam-installer`
- `lutris`
- Heroic Games Launcher (via Flatpak)
- `playonlinux` (opcional, legado)

### Otimização e overlay
- `gamemode` — otimização automática durante jogos
- `mangohud` — overlay de performance
- `goverlay` — GUI para configurar MangoHud
- `corectrl` — controle de GPU/CPU

### Emuladores (opcional)
- `retroarch` — front-end de emulação
- `dolphin-emu` — GameCube/Wii
- `pcsx2` — PlayStation 2
- `ppsspp` — PSP

## Pilar 3: Usuário comum + Office

### Suite de escritório
- `libreoffice` — suite completa
- `libreoffice-kf5` — integração KDE
- `onlyoffice-desktopeditors` — alternativa fiel ao MS Office

### Navegadores
- `firefox`
- `chromium-browser`
- Brave (via repositório oficial, opcional)

### Comunicação
- `thunderbird` — email
- `telegram-desktop`
- Discord (via Flatpak)
- Slack (via Flatpak, opcional)
- `signal-desktop`

### Multimídia
- `vlc` — player universal
- `mpv` — player minimalista
- `spotify-client` (via snap ou Flatpak)
- `audacity` — edição de áudio
- `obs-studio` — gravação e streaming

### Criação e edição
- `gimp` — edição de imagem
- `inkscape` — vetorial
- `krita` — pintura digital
- `kdenlive` — edição de vídeo
- `blender` — 3D

### Utilitários
- `kcalc` — calculadora
- `okular` — leitor de PDF
- `ark` — gerenciador de arquivos compactados
- `kate` — editor de texto
- `dolphin` — gerenciador de arquivos (já vem no KDE)
- `filelight` — análise de uso de disco
- `timeshift` — backup/snapshot do sistema

### Impressão e scanner
- `cups`, `cups-bsd`, `cups-client`
- `system-config-printer`
- `sane`, `sane-utils`, `simple-scan`
- `hplip` — impressoras HP

## Compatibilidade Windows (Wine)

- `wine-staging` — versão mais atual
- `winetricks` — instalador de componentes
- `bottles` (via Flatpak) — gerenciador de prefixos Wine
- Proton-GE (via ProtonUp-Qt)
- `protonup-qt` — instalador de Proton-GE

## Estimativa de espaço

| Categoria | Tamanho aprox. |
|-----------|----------------|
| Base + KDE | 4 GB |
| Tema + fontes | 500 MB |
| Todos os idiomas | 1.5 GB |
| Pilar Dev | 2 GB |
| Pilar Jogos (sem Steam baixado) | 500 MB |
| Pilar Office | 1.5 GB |
| Wine + Bottles | 500 MB |
| **Total instalado** | **~10 GB** |
| **ISO comprimida** | **~4-4.5 GB** |
