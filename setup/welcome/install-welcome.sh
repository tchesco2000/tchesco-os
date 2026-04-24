#!/usr/bin/env bash
# Instala o Tchesco Welcome no squashfs
# Executado dentro do chroot durante o rebuild da ISO

set -euo pipefail

LOGO_SRC="/home/ubuntu/tchesco-theme-build/tchesco-icon-kde.svg"
LOGO_DST="/usr/share/tchesco/logo/tchesco-icon-kde.svg"

# Dependência PyQt6 para o welcome app
apt-get install -y -qq python3-pyqt6 python3-pyqt6.qtsvg 2>/dev/null || true

# Diretório de assets
mkdir -p /usr/share/tchesco/logo

# Copia logo — tenta várias localizações possíveis
for src in \
    "/home/ubuntu/tchesco-theme-build/tchesco-icon-kde.svg" \
    "/usr/share/pixmaps/tchesco-icon-kde.svg" \
    "/usr/share/icons/tchesco-icon-kde.svg"; do
    if [[ -f "$src" ]]; then
        cp "$src" "$LOGO_DST"
        break
    fi
done

# Se não achou o SVG, cria um placeholder simples
if [[ ! -f "$LOGO_DST" ]]; then
    cat > "$LOGO_DST" << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" rx="20" fill="#0e1117"/>
  <text x="50" y="72" font-size="70" font-weight="bold" font-family="sans-serif"
        fill="#3d85c8" text-anchor="middle">T</text>
</svg>
SVGEOF
fi

# Instala o app welcome
cp /opt/tchesco-setup/tchesco-welcome /usr/local/bin/tchesco-welcome
chmod +x /usr/local/bin/tchesco-welcome

# .desktop na área de aplicações
cp /opt/tchesco-setup/tchesco-welcome.desktop /usr/share/applications/

# Autostart para sessão live
mkdir -p /etc/xdg/autostart
cp /opt/tchesco-setup/tchesco-welcome-autostart.desktop /etc/xdg/autostart/tchesco-welcome.desktop

# Remove o kubuntu-welcome do autostart
rm -f /etc/xdg/autostart/kubuntu-welcome.desktop \
      /etc/xdg/autostart/plasma-welcome.desktop \
      /etc/xdg/autostart/org.kde.plasma-welcome.desktop 2>/dev/null || true

# Ícone de instalar no desktop do usuário live
mkdir -p /home/ubuntu/Desktop
cp /usr/share/applications/tchesco-welcome.desktop /home/ubuntu/Desktop/
chmod +x /home/ubuntu/Desktop/tchesco-welcome.desktop
chown ubuntu:ubuntu /home/ubuntu/Desktop/tchesco-welcome.desktop

# Também no skel para qualquer novo usuário
mkdir -p /etc/skel/Desktop
cp /usr/share/applications/tchesco-welcome.desktop /etc/skel/Desktop/
chmod +x /etc/skel/Desktop/tchesco-welcome.desktop

echo "Tchesco Welcome instalado."
