@echo off
REM ============================================================
REM  Atencion Dgtal - Crear el ejecutable de Windows (v3.0)
REM  Genera dist\AtencionDgtal.exe : un solo archivo, sin instalar
REM  Python en las maquinas donde se ejecute.
REM  Guia completa: INSTALACION.md, seccion "Ejecutable de Windows".
REM ============================================================
setlocal enabledelayedexpansion
title Atencion Dgtal - Compilar ejecutable de Windows
cd /d "%~dp0"

echo.
echo === Atencion Dgtal - Compilador del ejecutable de Windows ===
echo.

REM -- [1/5] Python disponible --
where python >nul 2>nul
if errorlevel 1 (
  echo [X] Python no esta instalado. Instalalo desde https://www.python.org/downloads/
  echo     IMPORTANTE: marca "Add Python to PATH" durante la instalacion.
  pause
  exit /b 1
)
echo [OK] Python detectado

REM -- [2/5] Entorno virtual del compilador --
if not exist ".venv" (
  echo ^> Creando entorno virtual...
  python -m venv .venv || (echo [X] No se pudo crear .venv & pause & exit /b 1)
)
call .venv\Scripts\activate.bat
if errorlevel 1 (echo [X] No se pudo activar .venv & pause & exit /b 1)

echo ^> Instalando dependencias ^(flet, openai, python-dotenv, flet-desktop,
echo   flet-web, flet-cli y pyinstaller^)...
pip install -q -r requirements.txt pyinstaller flet-desktop==1.1.2 flet-web==1.1.2 flet-cli==1.1.2
if errorlevel 1 (
  echo [X] Fallo la instalacion de dependencias. Revisa tu conexion a internet.
  pause
  exit /b 1
)
echo [OK] Dependencias listas

REM -- [3/5] Version del proyecto --
set VERSION=1.0
for /f "usebackq delims=" %%i in (`type VERSION`) do set VERSION=%%i
echo [OK] Version del proyecto: !VERSION!

REM -- [4/5] Localizar los recursos web de flet (para el modo --web del exe) --
for /f "usebackq delims=" %%i in (`python -c "import flet_web, os; print(os.path.join(os.path.dirname(flet_web.__file__), 'web'))"`) do set WEBDIR=%%i
if not defined WEBDIR (
  echo [X] No encontre flet_web/web. Ejecuta: pip install flet-web==1.1.2
  pause
  exit /b 1
)
echo [OK] Recursos web: !WEBDIR!

REM -- [5/5] Compilar con flet pack (PyInstaller debajo) --
echo ^> Compilando... ^(puede tardar 5-15 minutos la primera vez; se descarga
echo   el cliente de Flet de Windows una sola vez^)...
python -m flet_cli.cli pack main.py ^
  -n AtencionDgtal ^
  --product-version "!VERSION!" ^
  --company-name "Atencion Dgtal" ^
  --add-data "!WEBDIR!;flet_web/web"
if errorlevel 1 (
  echo [X] La compilacion fallo. Revisa los mensajes de arriba.
  pause
  exit /b 1
)

echo.
echo [OK] Listo! Tu ejecutable esta en: dist\AtencionDgtal.exe
echo      - Copialo a cualquier Windows: doble clic y funciona.
echo      - data\, respaldos\ y .env se crean junto al .exe al usarlo.
echo      - Para compartir por navegador: AtencionDgtal.exe --web
echo.
pause
