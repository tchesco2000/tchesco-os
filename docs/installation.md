# Guia de Instalação do Tchesco OS

## Métodos de instalação

### Método 1: ISO Tchesco OS (recomendado)

Quando a ISO `tchesco-os-1.0.iso` estiver pronta:

1. Baixar a ISO
2. Validar checksum SHA256
3. Gravar em pendrive (mínimo 8 GB) com:
   - **Windows:** Rufus ou Balena Etcher
   - **Linux:** `dd` ou Balena Etcher
   - **macOS:** Balena Etcher
4. Bootar pelo pendrive
5. Seguir instalador Calamares (branding Tchesco)
6. Reiniciar após instalação

### Método 2: Kubuntu + script de pós-instalação

Para transformar um Kubuntu existente em Tchesco OS:

```bash
# Instalar Kubuntu 26.04 LTS normalmente
# Após primeiro boot no desktop:

# Clonar o repositório
sudo apt update && sudo apt install -y git
git clone https://github.com/SEU_USUARIO/tchesco-os.git
cd tchesco-os

# Dar permissão e executar
chmod +x scripts/tchesco-install.sh
sudo ./scripts/tchesco-install.sh

# Reiniciar ao terminar
sudo reboot
```

## Requisitos mínimos

- **CPU:** Processador 64-bit (x86_64)
- **RAM:** 4 GB (recomendado 8 GB)
- **Disco:** 40 GB livres
- **GPU:** Qualquer com suporte OpenGL 3.3 ou Vulkan
- **Internet:** necessária durante instalação

## GPUs suportadas

### NVIDIA
- **Turing (RTX 20xx) e mais novas:** perfeito, `nvidia-open` recomendado
- **Pascal (GTX 10xx):** funciona com driver proprietário
- **Maxwell (GTX 900) e Kepler (GTX 700):** funciona, performance limitada
- **Pré-Kepler:** apenas com `nouveau` (open-source)

### AMD
- **RDNA 3 e mais novas:** excelente
- **RDNA 2 (RX 6000):** excelente
- **RDNA 1 (RX 5000):** muito bom
- **Vega, Polaris (RX 400/500):** bom
- **GCN antigas:** funciona via `amdgpu`

### Intel
- **Arc (dedicadas):** bom, driver Xe
- **Integradas recentes (Iris Xe, UHD):** excelente
- **Integradas antigas (HD Graphics):** funciona

## Primeira inicialização

Ao iniciar o Tchesco OS pela primeira vez:

1. Login com usuário criado na instalação
2. Sistema inicia em Português (Brasil)
3. Wizard de boas-vindas (futuro) oferece:
   - Trocar idioma se desejado
   - Configurar conta online (opcional)
   - Tour rápido pela interface
4. Atualizações iniciais recomendadas via `Discover`

## Pós-instalação

Recomendações para melhor experiência:

### Atualizar sistema

```bash
sudo apt update && sudo apt upgrade -y
```

### Instalar codecs adicionais (se não vieram na ISO)

```bash
sudo apt install ubuntu-restricted-extras
```

### Configurar Flatpak (já vem instalado)

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

### Habilitar Firewall

```bash
sudo ufw enable
```

### Configurar backup (Timeshift já vem instalado)

Abrir Timeshift e criar primeiro snapshot.

## Solução de problemas comuns

### Tela preta ao bootar

Causa provável: driver NVIDIA.

Solução:
1. No GRUB, pressionar `e` para editar
2. Adicionar `nomodeset` na linha do kernel
3. Pressionar F10 para bootar
4. No sistema, rodar: `sudo ubuntu-drivers autoinstall`
5. Reiniciar

### Wi-Fi não funciona

Causa provável: firmware faltando.

Solução:
```bash
sudo apt install linux-firmware
sudo reboot
```

### Áudio não funciona

```bash
# Verificar se PipeWire está rodando
systemctl --user status pipewire

# Se não estiver, habilitar
systemctl --user enable --now pipewire pipewire-pulse
```

### Steam não abre

```bash
# Instalar libs 32-bit
sudo apt install libgl1-mesa-glx:i386 libc6:i386
```

### Jogo não roda via Proton

1. Abrir Steam
2. Biblioteca → clicar com botão direito no jogo → Propriedades
3. Compatibilidade → marcar "Forçar uso de ferramenta de compatibilidade"
4. Selecionar versão mais recente do Proton ou Proton-GE

## Desinstalar Tchesco OS

Como Tchesco OS é baseado em Ubuntu, desinstalação é igual ao Ubuntu:

1. Bootar com pendrive de outra distro ou Windows
2. Remover/reformatar partição do Tchesco OS
3. Restaurar boot (GRUB ou Windows Boot Manager)

Recomenda-se fazer backup antes via Timeshift.

## Reportar bugs

Enquanto o projeto estiver em fase pessoal, reportar diretamente pros amigos ou via Issues do GitHub (se o repo for público).
