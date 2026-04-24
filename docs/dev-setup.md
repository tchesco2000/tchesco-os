# Configuração do ambiente de desenvolvimento

Guia passo a passo para preparar tudo antes de começar a codar o Tchesco OS.

## Pré-requisitos

- Windows 10/11 com WSL2 Ubuntu instalado
- Claude Code instalado no WSL
- Conta no GitHub
- Pelo menos 100 GB livres no disco
- Pelo menos 16 GB de RAM (8 GB pra VM + Windows)

## Passo 1: Instalar VirtualBox no Windows

1. Acessar https://www.virtualbox.org/wiki/Downloads
2. Baixar "Windows hosts"
3. Instalar com configurações padrão
4. Baixar também o "VirtualBox Extension Pack" (mesma página)
5. Instalar o Extension Pack pelo menu: Arquivo → Ferramentas → Gerenciador de Extensões

## Passo 2: Baixar ISO do Kubuntu 26.04 LTS

1. Acessar https://kubuntu.org/getkubuntu/
2. Baixar Kubuntu 26.04 LTS (64-bit)
3. Validar checksum SHA256 (baixar do site oficial)
4. Salvar em pasta organizada, por exemplo `C:\ISOs\`

## Passo 3: Criar VM do Tchesco OS

No VirtualBox:

1. Clicar em "Novo"
2. Nome: `Tchesco-OS-Dev`
3. Tipo: Linux
4. Versão: Ubuntu (64-bit)
5. Memória RAM: 4096 MB (mínimo) a 8192 MB (recomendado)
6. Disco: criar novo, VDI, alocação dinâmica, 60 GB
7. Após criar, ir em Configurações:
   - **Sistema → Processador:** 2-4 CPUs
   - **Tela → Memória de Vídeo:** 128 MB
   - **Tela → Controladora Gráfica:** VMSVGA
   - **Tela → Habilitar aceleração 3D:** marcar
   - **Armazenamento:** adicionar ISO Kubuntu no drive óptico
   - **USB:** habilitar USB 3.0
   - **Rede:** NAT (padrão já serve)

## Passo 4: Configurar Git no WSL

```bash
# No WSL Ubuntu
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"
git config --global init.defaultBranch main

# Gerar chave SSH pro GitHub (se ainda não tiver)
ssh-keygen -t ed25519 -C "seu@email.com"
cat ~/.ssh/id_ed25519.pub
# Copiar essa chave e adicionar em GitHub → Settings → SSH keys
```

## Passo 5: Criar repositório no GitHub

1. Acessar https://github.com/new
2. Nome: `tchesco-os`
3. Descrição: "Distribuição Linux baseada em Ubuntu 26.04 com visual macOS"
4. Público ou privado (recomendo privado no começo)
5. NÃO inicializar com README (vamos subir o nosso)
6. Criar repositório

## Passo 6: Clonar e organizar o repositório no WSL

```bash
# No WSL Ubuntu
cd ~
mkdir -p projetos
cd projetos

# Clonar o repo recém-criado
git clone git@github.com:SEU_USUARIO/tchesco-os.git
cd tchesco-os

# Criar estrutura inicial
mkdir -p scripts/modules
mkdir -p assets/{wallpapers,logo,plymouth}
mkdir -p config/{kde-plasma,latte}
mkdir -p docs
mkdir -p tests

# Criar .gitignore
cat > .gitignore << 'EOF'
*.iso
*.log
build/
dist/
*.tmp
.DS_Store
EOF

# Primeiro commit
git add .
git commit -m "chore: estrutura inicial do projeto"
git push origin main
```

## Passo 7: Preparar Claude Code

Abrir o projeto no Claude Code:

```bash
cd ~/projetos/tchesco-os
claude
```

A partir daí, todo desenvolvimento de scripts será feito via Claude Code, que pode editar arquivos diretamente no repositório.

## Passo 8: Configurar compartilhamento entre WSL e VirtualBox

Duas opções para transferir scripts pro ambiente de teste:

**Opção A (recomendada): clonar repo dentro da VM**

Na VM Kubuntu, após instalar:
```bash
sudo apt install git
git clone https://github.com/SEU_USUARIO/tchesco-os.git
cd tchesco-os
```

A cada mudança, fazer `git pull` na VM para pegar atualizações.

**Opção B: pasta compartilhada do VirtualBox**

1. VirtualBox → Configurações da VM → Pastas Compartilhadas
2. Adicionar pasta do WSL (caminho no Windows: `\\wsl$\Ubuntu\home\usuario\projetos\tchesco-os`)
3. Marcar "Automontar"
4. Na VM: `sudo usermod -aG vboxsf $USER`

## Estrutura final esperada

```
tchesco-os/
├── README.md
├── .gitignore
├── scripts/
│   ├── tchesco-install.sh
│   └── modules/
│       ├── 01-base.sh
│       ├── 02-theme.sh
│       ├── 02b-i18n.sh
│       ├── 03-dev.sh
│       ├── 04-gaming.sh
│       ├── 05-office.sh
│       └── 06-wine.sh
├── assets/
│   ├── wallpapers/
│   │   └── tchesco-default.jpg
│   ├── logo/
│   │   └── tchesco-logo.svg
│   └── plymouth/
│       └── tchesco-theme/
├── config/
│   ├── kde-plasma/
│   │   └── plasma-config-backup/
│   └── latte/
│       └── tchesco-dock.layout.latte
├── docs/
│   ├── architecture.md
│   ├── packages.md
│   ├── roadmap.md
│   ├── installation.md
│   ├── i18n.md
│   └── dev-setup.md
└── tests/
    └── vm-test-checklist.md
```

## Checklist final antes de codar

- [ ] VirtualBox instalado e funcionando
- [ ] ISO Kubuntu 26.04 baixada e validada
- [ ] VM criada com configurações recomendadas
- [ ] WSL Ubuntu atualizado (`sudo apt update && sudo apt upgrade`)
- [ ] Git configurado com nome e email
- [ ] SSH key adicionada no GitHub
- [ ] Repositório `tchesco-os` criado no GitHub
- [ ] Repositório clonado no WSL
- [ ] Estrutura de pastas criada
- [ ] Claude Code funcionando no WSL
- [ ] Primeiro commit feito e pushado

Quando todos estiverem marcados, estamos prontos pra Fase 1.
