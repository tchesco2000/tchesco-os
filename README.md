# Tchesco OS

> Uma distribuição Linux com a alma do macOS, o coração do Ubuntu e o sangue lusófono.

## Visão

Tchesco OS é uma distribuição Linux baseada em Ubuntu 26.04 LTS com visual inspirado no macOS, focada em três pilares:

1. **Desenvolvimento** — ambiente completo para devs (VS Code, Docker, Node, Rust, Go)
2. **Jogos** — Steam, Proton, Lutris prontos pra usar
3. **Usuário comum** — office robusto, multimídia, produtividade

## Status atual

- **Versão:** 1.0-dev (em desenvolvimento ativo)
- **Data de início:** Abril de 2026
- **Base:** Ubuntu 26.04 LTS (Resolute Raccoon)
- **Desktop:** KDE Plasma 6.6.4 — **X11 (plasmax11)**
- **Idioma padrão:** Português (Brasil)
- **VM de teste:** 192.168.0.24 (user: suporte)

## Fases de desenvolvimento

| Fase | Script | Status |
|---|---|---|
| Fase 0 | — | ✅ Repo GitHub + estrutura inicial |
| Fase 1 | — | ✅ VM Kubuntu 26.04 funcionando |
| Fase 2 | 01-base.sh | ✅ Base Ubuntu, locale, timezone, utilitários |
| Fase 3 | 02-theme.sh | ✅ Visual macOS: WhiteSur, Plank, splash, SDDM, X11 |
| Fase 3.5 | 02b-i18n.sh | ✅ 11 idiomas + fcitx5 JP/CN/KR + fontes |
| Fase 4 | 03-dev.sh | ✅ VS Code, Docker, Node/nvm, Rust, Go, DBeaver |
| Fase 5 | 04-gaming.sh | ⏳ Steam, Lutris, GameMode, MangoHud, ProtonUp-Qt |
| Fase 6 | 05-office.sh | ⏳ LibreOffice, OnlyOffice, VLC, GIMP, OBS |
| Fase 7 | 06-wine.sh | ⏳ Wine Staging, Winetricks, Bottles |
| Fase 8 | — | ⏳ Testes limpos + consolidação |
| Fase 9 | — | ⏳ Identidade: /etc/os-release, "Sobre o Sistema" |
| Fase 10 | — | ⏳ Geração da ISO (Cubic + Calamares) |
| Fase 11 | — | ⏳ Distribuição pública |

## Visual implementado

- **Tema:** WhiteSur GTK + KDE (sem referências Apple)
- **Dock:** Plank centralizado, 8 apps fixos, IntelligentHide, zoom 150%
- **Top bar:** Logo T → Global Menu → Busca → Bandeja → Relógio
- **Boot:** Plymouth breeze-text (sem Apple)
- **Login:** SDDM breeze com logo Tchesco + fundo escuro `#0e1117`
- **Wallpaper:** Gradient azul-marinho escuro (Tchesco)
- **Firefox:** deb oficial Mozilla (não snap) com menus funcionais

## Como instalar (na VM)

```bash
git clone https://github.com/tchesco2000/tchesco-os.git
cd tchesco-os
sudo bash scripts/tchesco-install.sh
```

## Documentação

- [Arquitetura e decisões técnicas](docs/architecture.md)
- [Roadmap detalhado](docs/roadmap.md)
- [Lista completa de pacotes](docs/packages.md)
- [Guia de instalação](docs/installation.md)
- [Internacionalização](docs/i18n.md)
- [CLAUDE.md](CLAUDE.md) — guia para o assistente de IA

## Licença

GPL v3 — compatível com Ubuntu/Debian.

## Autor

Projeto pessoal. Iniciado em abril de 2026.
