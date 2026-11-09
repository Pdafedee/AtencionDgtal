@echo off
REM Atencion Dgtal - asistente de respaldo de configuracion (Windows)
cd /d "%~dp0"
if exist ".venv" call .venv\Scripts\activate.bat
set PYTHONIOENCODING=utf-8
python asistente_respaldo.py
pause
