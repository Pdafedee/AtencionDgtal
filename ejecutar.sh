#!/usr/bin/env bash
# Atención Dgtal — lanzador rápido (Linux/Mac)
cd "$(dirname "$0")"
if [ ! -d ".venv" ]; then
  echo "→ Creando entorno virtual…"
  python3 -m venv .venv
  source .venv/bin/activate
  echo "→ Instalando dependencias…"
  pip install -r requirements.txt
else
  source .venv/bin/activate
fi
python main.py "$@"
