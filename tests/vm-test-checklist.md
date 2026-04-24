# Checklist de Testes do Tchesco OS

Checklist para validar o Tchesco OS antes de considerar uma versão pronta. Todos os testes devem ser feitos em **VM limpa** (snapshot recente do Kubuntu zerado).

## Teste 1: Instalação limpa

- [ ] VM inicia a partir da ISO do Kubuntu
- [ ] Instalador Calamares funciona
- [ ] Instalação completa em menos de 20 minutos
- [ ] Primeiro boot chega no desktop

## Teste 2: Script de instalação

- [ ] Script `tchesco-install.sh` executa sem erros
- [ ] Todos os módulos rodam na ordem correta
- [ ] Logs são gerados em `/var/log/tchesco-install.log`
- [ ] Tempo total do script: menos de 30 minutos
- [ ] Nenhum pacote fica pendente (`apt check` limpo)

## Teste 3: Identidade visual

- [ ] Tema WhiteSur aplicado no KDE
- [ ] Ícones WhiteSur/McMojave visíveis
- [ ] Cursor macOS aplicado
- [ ] Latte Dock aparece na parte inferior
- [ ] Menu global (app menu) no topo
- [ ] Wallpaper Tchesco OS carregado
- [ ] Plymouth (boot splash) exibindo logo Tchesco

## Teste 4: Multi-idioma

- [ ] Sistema inicia em Português (Brasil) por padrão
- [ ] Trocar para Inglês: interface toda traduz
- [ ] Trocar para Espanhol: interface toda traduz
- [ ] Trocar para Francês: interface toda traduz
- [ ] Trocar para Alemão: interface toda traduz
- [ ] Voltar para PT-BR: funciona sem glitches
- [ ] LibreOffice abre com corretor ortográfico PT-BR
- [ ] fcitx5 permite digitar hiragana (japonês)
- [ ] fcitx5 permite digitar pinyin (chinês)
- [ ] Caracteres CJK aparecem (não são quadradinhos)
- [ ] Emojis coloridos renderizam (🎉🇧🇷🚀)
- [ ] Layout ABNT2 funciona (ç, ã, é digitam corretamente)

## Teste 5: Pilar Desenvolvimento

- [ ] VS Code abre e funciona
- [ ] Extensões VS Code instalam
- [ ] Git clone funciona via HTTPS e SSH
- [ ] `docker run hello-world` funciona
- [ ] Python 3 executa scripts
- [ ] Node.js (via nvm) instala e funciona
- [ ] Rust (cargo) compila projeto simples
- [ ] Go compila projeto simples
- [ ] DBeaver abre
- [ ] Terminal (Konsole) funciona

## Teste 6: Pilar Jogos

- [ ] Steam abre
- [ ] Steam faz login
- [ ] Lutris abre
- [ ] Heroic abre
- [ ] GameMode ativa durante jogo (`gamemoded -s`)
- [ ] MangoHud mostra overlay
- [ ] ProtonUp-Qt abre
- [ ] Vulkan funciona (`vulkaninfo`)
- [ ] Driver NVIDIA detectado (`nvidia-smi`) — só em hardware real
- [ ] `ubuntu-drivers devices` lista corretamente

## Teste 7: Pilar Office

- [ ] LibreOffice Writer abre
- [ ] LibreOffice Calc abre
- [ ] LibreOffice Impress abre
- [ ] OnlyOffice abre
- [ ] Firefox abre e navega
- [ ] Thunderbird abre
- [ ] GIMP abre
- [ ] Inkscape abre
- [ ] Krita abre
- [ ] Kdenlive abre
- [ ] VLC reproduz vídeo MP4
- [ ] OBS Studio abre
- [ ] Impressão em PDF virtual funciona

## Teste 8: Compatibilidade Windows

- [ ] Bottles abre
- [ ] Bottles cria novo prefixo sem erro
- [ ] Wine roda `notepad.exe` (teste básico)
- [ ] Winetricks abre
- [ ] Um .exe simples (7-Zip portable) executa via Bottles

## Teste 9: Rede e conectividade

- [ ] Wi-Fi conecta (se tiver em VM com passthrough)
- [ ] Ethernet funciona
- [ ] DNS resolve corretamente
- [ ] Navegador carrega sites HTTPS

## Teste 10: Sistema e manutenção

- [ ] `apt update` funciona sem erros
- [ ] `apt upgrade` atualiza pacotes
- [ ] Discover (loja de apps) abre
- [ ] Flatpak instala pelo menos 1 app (teste: Telegram)
- [ ] Timeshift cria snapshot
- [ ] Sistema reinicia corretamente
- [ ] Sistema desliga corretamente
- [ ] Suspender e acordar funciona

## Teste 11: Usabilidade geral

- [ ] Tempo de boot: menos de 30 segundos
- [ ] Animações fluidas (sem travamentos)
- [ ] Busca global (KRunner) funciona
- [ ] Notificações aparecem corretamente
- [ ] Volume e brilho ajustam
- [ ] Captura de tela funciona (Spectacle)
- [ ] Arrastar arquivos funciona
- [ ] Dolphin (file manager) navega pastas

## Teste 12: Identidade Tchesco

- [ ] Cat `/etc/os-release` mostra "Tchesco OS 1.0"
- [ ] `neofetch` mostra Tchesco OS
- [ ] Sobre o Sistema (KDE) mostra Tchesco OS
- [ ] Logo Tchesco visível no menu
- [ ] Splash de boot mostra Tchesco

## Critério de aprovação v1.0

Para considerar a v1.0 pronta para distribuição entre amigos:

- **Mínimo 95%** dos testes acima passando
- **Zero bugs bloqueadores** (que impedem uso básico)
- **Tempo de boot menor que 45s**
- **Pelo menos 1 teste completo em hardware real** (não só VM)

## Registro de testes

Data do teste: _______________
Versão testada: _______________
VM ou hardware: _______________
Testes passando: ___/___
Observações:
