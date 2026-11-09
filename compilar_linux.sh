#!/usr/bin/env bash
# Atención Dgtal — crear el ejecutable de Linux/Mac (v3.0)
# Genera dist/AtencionDgtal (binario único). Guía: INSTALACION.md
set -euo pipefail
cd "$(dirname "$0")"

command -v python3 >/dev/null 2>&1 || { echo "✘ Python 3 no está instalado."; exit 1; }

if [ ! -d ".venv" ]; then
  echo "→ Creando entorno virtual…"
  python3 -m venv .venv
fi
source .venv/bin/activate

echo "→ Instalando dependencias (incluye PyInstaller y el runtime de escritorio)…"
pip install -q -r requirements.txt pyinstaller flet-desktop==1.1.2 flet-web==1.1.2 flet-cli==1.1.2

VERSION="$(tr -d ' \n' < VERSION)"
echo "→ Versión del proyecto: $VERSION"

WEBDIR="$(python3 -c "import flet_web, os; print(os.path.join(os.path.dirname(flet_web.__file__), 'web'))")"

echo "→ Compilando (5-15 min la primera vez)…"
python3 -m flet_cli.cli pack main.py \
  -n AtencionDgtal \
  --product-version "$VERSION" \
  --company-name "Atencion Dgtal" \
  --add-data "$WEBDIR:flet_web/web"

echo "✔ Listo: dist/AtencionDgtal (en Mac: dist/AtencionDgtal.app)"
