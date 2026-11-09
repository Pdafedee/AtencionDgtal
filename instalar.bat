@echo off
REM ═══════════════════════════════════════════════════════════════════════
REM  Atención Dgtal — Instalador automático (Windows)
REM
REM  Uso:  doble clic sobre instalar.bat   (o ejecutarlo desde cmd)
REM  Qué hace:
REM    1. Localiza un Python 3.10+ en el sistema
REM    2. Crea el entorno virtual .venv (aislado del sistema)
REM    3. Instala las dependencias (flet, openai, python-dotenv)
REM    4. Crea tu .env personal desde .env.example (sin sobrescribir)
REM    5. Verifica TODO el sistema con verificar.py
REM ═══════════════════════════════════════════════════════════════════════
setlocal EnableDelayedExpansion
cd /d "%~dp0"
chcp 65001 >nul
set "PYTHONIOENCODING=utf-8"

echo.
echo ============================================================
echo    Atención Dgtal - Instalador automatico (Windows)
echo ============================================================
echo.
echo Carpeta del proyecto: %CD%

REM ── Paso 1: localizar Python 3.10+ ──────────────────────────────────
echo.
echo → Paso 1/5 . Buscando Python 3.10 o superior...
set "PYTHON="
for %%P in (py python3.12 python3.11 python3.10 python) do (
    if not defined PYTHON (
        %%P -c "import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)" >nul 2>&1
        if !errorlevel! equ 0 set "PYTHON=%%P"
    )
)

if not defined PYTHON (
    echo    [X] No se encontro Python 3.10 o superior.
    echo.
    echo    Instalalo desde https://www.python.org/downloads/
    echo    IMPORTANTE: marca la casilla "Add python.exe to PATH" al instalar.
    echo    Luego vuelve a ejecutar este archivo.
    pause
    exit /b 1
)
for /f "usebackq delims=" %%V in (`%PYTHON% -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')"`) do set "VER=%%V"
echo    [OK] Encontrado: %PYTHON% (version %VER%)

REM ── Paso 2: entorno virtual ─────────────────────────────────────────
echo.
echo → Paso 2/5 . Preparando entorno virtual (.venv)...
if exist ".venv\Scripts\python.exe" (
    echo    [OK] Ya existia, se reutiliza.
) else (
    %PYTHON% -m venv .venv
    if errorlevel 1 (
        echo    [X] No se pudo crear el entorno virtual.
        pause
        exit /b 1
    )
    echo    [OK] Entorno .venv creado.
)
call .venv\Scripts\activate.bat

REM ── Paso 3: dependencias ────────────────────────────────────────────
echo.
echo → Paso 3/5 . Instalando dependencias (puede tardar 1-3 minutos)...
python -m pip install --upgrade pip --quiet
python -m pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo    [X] pip no pudo instalar las dependencias.
    echo    Revisa tu conexion a internet y vuelve a intentar:
    echo        python -m pip install -r requirements.txt
    pause
    exit /b 1
)
echo    [OK] flet + openai + python-dotenv instalados.

REM ── Paso 4: configuracion personal ──────────────────────────────────
echo.
echo → Paso 4/5 . Configuracion (.env)...
if exist ".env" (
    echo    [OK] .env ya existe, se conserva tu configuracion.
) else (
    copy /Y .env.example .env >nul
    echo    [OK] .env creado desde .env.example.
    echo    [i] Sin clave OpenAI funciona en MODO DEMO (simulador local, costo 0^).
    echo    [i] Para GPT real edita .env y llena OPENAI_API_KEY.
)

REM ── Paso 5: verificacion completa ───────────────────────────────────
echo.
echo → Paso 5/5 . Verificando la instalacion...
echo.
python verificar.py
set "RESULTADO=%errorlevel%"
echo.

if "%RESULTADO%" equ "0" (
    echo ============================================================
    echo    INSTALACION TERMINADA - todo listo para usarse
    echo ============================================================
    echo.
    echo    Para arrancar la aplicacion:
    echo        ejecutar.bat              (app de escritorio)
    echo        ejecutar.bat --web        (navegador: http://localhost:8550^)
    echo.
    echo    Estos comandos activan el .venv solos; no necesitas nada mas.
) else (
    echo La verificacion detecto problemas. Revisa los [X] de arriba
    echo o consulta INSTALACION.md ^(seccion "Solucion de problemas"^).
)
pause
exit /b %RESULTADO%
