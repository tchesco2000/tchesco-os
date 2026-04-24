# Arquitetura do Tchesco OS

## Camadas do sistema

```
┌─────────────────────────────────────────────┐
│  Identidade Tchesco (wallpaper, logo, nome) │
├─────────────────────────────────────────────┤
│  Aplicações (Dev + Jogos + Office + Wine)   │
├─────────────────────────────────────────────┤
│  Tema macOS (WhiteSur, Latte Dock, ícones)  │
├─────────────────────────────────────────────┤
│  KDE Plasma 6 (ambiente gráfico)            │
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
- 100% gratuito, sem necessidade de compra ou assinatura

### Por que KDE Plasma 6 e não GNOME?

- Customização profunda sem extensões
- Menu global nativo (essencial para visual macOS)
- Latte Dock e widgets de painel flexíveis
- Temas macOS mais fiéis no KDE do que no GNOME
- Extensões GNOME quebram a cada atualização

### Por que tema WhiteSur/Sequoia?

- Projetos ativamente mantidos
- Cobrem GTK, Qt/KDE, ícones, cursor e Plymouth
- Comunidade grande com suporte
- Gratuitos e open-source

### Estratégia de drivers de vídeo

**NVIDIA:**
- Arquitetura Turing ou mais nova (RTX 20xx+): `nvidia-open` (recomendado)
- Blackwell (RTX 50xx): obrigatório `nvidia-open`
- Arquiteturas antigas (GTX 900 e anteriores): `nvidia-driver` proprietário
- Muito antigas (pré-Kepler): `nouveau` (open-source, performance limitada)

**AMD:**
- Driver `amdgpu` (open-source) vem no kernel
- Mesa mais recente via PPA kisak-mesa para melhor performance Vulkan
- Firmware via `firmware-amd-graphics`

**Intel:**
- Driver `i915` (open-source) vem no kernel
- Mesa mais recente via PPA kisak-mesa
- Suporte Xe para GPUs dedicadas Arc

### Compatibilidade Windows (Wine)

Três ferramentas combinadas cobrem cenários diferentes:

- **Bottles** — usuário comum quer rodar um .exe simples
- **Steam + Proton-GE** — jogos da Steam
- **Lutris + Heroic** — jogos fora da Steam (Epic, GOG, Battle.net)

### Multi-idioma

- Locale padrão: `pt_BR.UTF-8`
- Todos os `language-pack-*` do Ubuntu instalados
- Fontes Noto completas (cobre todos os alfabetos do mundo)
- fcitx5 como input method para idiomas asiáticos
- Layouts de teclado múltiplos pré-configurados

## Fluxo de construção

```
Kubuntu 26.04 ISO oficial
        ↓
Instalação em VM VirtualBox
        ↓
Script tchesco-install.sh
        ↓
Sistema personalizado pronto
        ↓
Cubic empacota nova ISO
        ↓
Tchesco OS 1.0.iso
        ↓
Distribuição entre amigos
```

## Requisitos mínimos de hardware

### Para rodar Tchesco OS

- **CPU:** 2 núcleos 64-bit (x86_64)
- **RAM:** 4 GB (recomendado 8 GB)
- **Disco:** 40 GB
- **GPU:** Qualquer GPU com suporte Vulkan ou OpenGL 3.3+

### Para desenvolvimento do Tchesco OS

- **CPU:** 4 núcleos
- **RAM:** 16 GB (VM + Windows host)
- **Disco:** 100 GB livres (VMs + ISOs + builds)
- **Internet:** banda larga estável
