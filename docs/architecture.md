# Arquitetura do Tchesco OS

## Camadas do sistema

```
┌─────────────────────────────────────────────┐
│  Identidade Tchesco (wallpaper, logo, nome) │
├─────────────────────────────────────────────┤
│  Aplicações (Dev + Jogos + Office + Wine)   │
├─────────────────────────────────────────────┤
│  Tema macOS (WhiteSur, Plank, ícones)       │
├─────────────────────────────────────────────┤
│  KDE Plasma 6 — X11 (plasmax11)             │
├─────────────────────────────────────────────┤
│  Ubuntu 26.04 LTS (base, apt, systemd)      │
├─────────────────────────────────────────────┤
│  Kernel Linux 7.0                           │
└─────────────────────────────────────────────┘
```

## Decisões arquiteturais

### Por que Ubuntu 26.04 LTS?

- Kernel 7.0 nativo (lançado em abril de 2026)
- Suporte oficial de 5 anos pela Canonical
- Repositório com mais de 75 mil pacotes
- Drivers NVIDIA empacotados e testados oficialmente
- `ubuntu-drivers autoinstall` detecta hardware automaticamente
- 100% gratuito

### Por que KDE Plasma 6 e não GNOME?

- Customização profunda sem extensões
- Menu global nativo (essencial para visual macOS)
- Temas macOS mais fiéis no KDE do que no GNOME
- Plank dock funciona nativamente em X11+KDE
- Extensões GNOME quebram a cada atualização

### Por que X11 e não Wayland? (decisão crítica)

Kubuntu 26.04 vem com Wayland por padrão, mas o Tchesco OS usa **plasmax11** por três motivos:

1. **Plank dock** — só funciona em X11. Wayland não expõe a API que o Plank precisa para `XDG_SESSION_TYPE=x11`.
2. **Global Menu** — `appmenu-gtk-module` não funciona em Wayland nativo. Apps GTK não exportam menus via DBus sem o módulo.
3. **AutoHide estável** — hover-to-reveal do dock é intermitente em Wayland com KWin; em X11 funciona de forma confiável.

Configurado em `/etc/sddm.conf.d/30-tchesco-x11.conf`:
```
[Autologin]
User=suporte
Session=plasmax11
```

Sessão Wayland (`plasma.desktop`) oculta via `/etc/xdg/wayland-sessions/plasma.desktop` com `Hidden=true`.

### Por que Plank e não Latte Dock?

- Latte Dock foi **descontinuado** em 2023 e não tem suporte no Plasma 6
- Plank funciona perfeitamente em X11 + KDE Plasma 6
- AutoHide `HideMode=1` (Intelligent) + `PressureReveal=true` replicam o comportamento do macOS Dock
- Zoom de ícones com `ZoomPercent=150` igual ao efeito macOS

### Por que Firefox deb e não snap?

- Snaps rodam em sandbox e **não exportam menus DBus** para o Global Menu do KDE
- Firefox deb (repositório `packages.mozilla.org`) exporta menus normalmente via `appmenu-gtk-module`
- Configurado via `policies.json` para manter `ui.key.menuAccessKeyFocuses=false` (menus ficam dentro da janela)

### Por que tema WhiteSur?

- Projetos ativamente mantidos (vinceliuice/WhiteSur-gtk-theme, WhiteSur-kde)
- Cobrem GTK3/4, Qt/KDE, ícones, cursor e Plymouth
- Gratuitos e open-source

Referências Apple removidas pós-instalação:
- Plymouth: `breeze-text` em vez de `kubuntu-logo`
- Wallpapers WhiteSur (`*.jpg`) substituídos por gradient Tchesco gerado via PIL
- SDDM: fundo `#0e1117` + logo Tchesco em vez de macOS

### Configuração do painel Plasma (Containment)

O Plasma 6 gerencia painéis via `~/.config/plasma-org.kde.plasma.desktop-appletsrc`.

IDs fixos usados pelo Tchesco OS:
- `[Containments][1]` — Desktop (plugin `org.kde.plasma.folder`, activityId detectado via DBus)
- `[Containments][29]` — Top panel (location=3, thickness=44px)

O Plasma cria automaticamente Containments extras (id 49, 52, 55, etc.) quando não reconhece nossa config. A função `cleanup_residual_panels()` remove todos fora do allowlist `{1, 29}` após cada execução do script.

**Chave crítica:** `activityId` no Containment do desktop NÃO pode ficar vazio — o Plasma rejeita e cria outro Containment, que renderiza o ToolBoxButton "Add Widgets" sobre o Plank.

### Estratégia de drivers de vídeo

**NVIDIA:**
- RTX 20xx+ (Turing): `nvidia-open` (recomendado)
- RTX 50xx (Blackwell): obrigatório `nvidia-open`
- GTX 900 e anteriores: `nvidia-driver` proprietário
- Pré-Kepler: `nouveau`

**AMD:**
- Driver `amdgpu` vem no kernel
- Firmware via `firmware-amd-graphics`

**Intel:**
- Driver `i915` vem no kernel
- Suporte Xe para GPUs Arc

### Compatibilidade Windows

- **Bottles** — usuário comum, .exe simples
- **Steam + Proton-GE** — jogos Steam
- **Lutris + Heroic** — Epic, GOG, Battle.net

### Multi-idioma

- Locale padrão: `pt_BR.UTF-8`
- 11 language-packs instalados
- Noto Fonts completo (todos os alfabetos)
- fcitx5 para japonês (mozc), chinês (chinese-addons), coreano (hangul)

## Fluxo de construção

```
Kubuntu 26.04 ISO oficial
        ↓
Instalação em VM VirtualBox
        ↓
sudo bash scripts/tchesco-install.sh
        ↓
Sistema personalizado pronto
        ↓
Cubic empacota nova ISO
        ↓
Tchesco OS 1.0.iso
        ↓
Distribuição
```

## Requisitos mínimos de hardware

### Para rodar Tchesco OS

- **CPU:** 2 núcleos 64-bit (x86_64)
- **RAM:** 4 GB (recomendado 8 GB)
- **Disco:** 40 GB
- **GPU:** Qualquer com Vulkan ou OpenGL 3.3+

### Para desenvolvimento

- **CPU:** 4 núcleos
- **RAM:** 16 GB (VM + host Windows)
- **Disco:** 100 GB livres
- **Internet:** banda larga estável
