#!/usr/bin/env bash
set -euo pipefail

echo -e "\n 🤗 PANELx8 + BHTTP — INSTALADOR OFICIAL"
echo "=========================================="

# Verificar root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Ejecutá como root: sudo ./instalar.sh"
  exit 1
fi

# Instalar BHTTP
echo "📦 Instalando BHTTP..."
mkdir -p /etc/ADMcgh/bin
cp BHTTP-binario /etc/ADMcgh/bin/BHTTP
chmod +x /etc/ADMcgh/bin/BHTTP

# Instalar Panel
echo "🖥️ Instalando Panel..."
cp panelx8.sh /usr/local/bin/panelx8
chmod +x /usr/local/bin/panelx8

echo -e "\n✅ ¡TODO LISTO!"
echo "👉 Ejecutá: panel.sh"
