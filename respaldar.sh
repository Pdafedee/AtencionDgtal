#!/usr/bin/env bash
# Atención Dgtal — asistente de respaldo de configuración (Linux/Mac)
cd "$(dirname "$0")"
if [ -d ".venv" ]; then
  source .venv/bin/activate
fi
python3 asistente_respaldo.py
