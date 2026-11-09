@echo off
REM Atención Dgtal — lanzador rápido (Windows)
cd /d "%~dp0"
if not exist ".venv" (
  echo ^> Creando entorno virtual...
  python -m venv .venv
  call .venv\Scripts\activate.bat
  echo ^> Instalando dependencias...
  pip install -r requirements.txt
) else (
  call .venv\Scripts\activate.bat
)
python main.py %*
