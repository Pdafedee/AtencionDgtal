@echo off
setlocal enabledelayedexpansion
title Atencion Dgtal - Publicar en GitHub

echo.
echo === Atencion Dgtal - Publicar en GitHub ===
echo.

rem -- [1/6] Git instalado --
where git >nul 2>nul
if errorlevel 1 (
  echo [X] Git no esta instalado. Descargalo de https://git-scm.com/downloads
  pause
  exit /b 1
)

rem -- [2/6] Identidad de Git, solo la primera vez en esta maquina --
set GN=
set GE=
for /f "usebackq delims=" %%i in (`git config user.name 2^>nul`) do set GN=%%i
if not defined GN (
  set /p GN=  Tu nombre y apellido:
  set /p GE=  Tu correo electronico:
  git config --global user.name "!GN!"
  git config --global user.email "!GE!"
  echo [OK] Identidad guardada: !GN!
) else (
  echo [OK] Identidad: !GN!
)

rem -- [3/6] Repositorio local --
if exist .git (
  echo [OK] El repositorio local ya existia: no se toca nada
) else (
  git init -b main >nul 2>nul
  if errorlevel 1 (
    git init >nul
    git branch -M main
  )
  echo [OK] Repositorio local creado, rama main
)

rem -- [4/6] Primera version guardada en el historial --
git add -A
set CAMBIOS=0
for /f "usebackq delims=" %%i in (`git status --porcelain 2^>nul ^| find /c /v ""`) do set CAMBIOS=%%i
if not "!CAMBIOS!"=="0" (
  git commit -m "Primera version de Atencion Dgtal" >nul
  echo [OK] Primera version guardada en el historial
) else (
  echo [OK] No hay cambios nuevos que guardar
)

rem -- [5/6] Conectar con el repositorio de GitHub --
set URL=%~1
if "%URL%"=="" (
  echo   Si aun no creaste el repositorio: https://github.com/new - guia: GITHUB.md apartado 3
  set /p URL=  Pega la direccion HTTPS del repositorio:
)
if "%URL%"=="" (
  echo [X] Necesito la direccion del repositorio.
  pause
  exit /b 1
)
git remote get-url origin >nul 2>nul
if errorlevel 1 (git remote add origin "%URL%") else (git remote set-url origin "%URL%")
echo [OK] Conectado a "%URL%"

rem -- [6/6] Publicar --
echo   GitHub pedira usuario y contrasena: la contrasena es tu Personal Access Token
echo   - como crearlo: GITHUB.md apartado 5 -
git push -u origin main
if errorlevel 1 (
  echo [X] No se pudo subir. Causas tipicas:
  echo     1. Token incorrecto o vencido: genera otro - GITHUB.md apartado 5.
  echo     2. El repositorio ya tenia contenido: ejecuta en esta carpeta:
  echo        git pull origin main --allow-unrelated-histories
  echo        y despues: git push -u origin main
  pause
  exit /b 1
)
echo.
echo [OK] Proyecto publicado en GitHub.
echo      Cada cambio futuro lo subes con:  sincronizar.bat "mensaje"
echo      Y los cambios de otra maquina:    actualizar.bat
echo      Guia completa: GITHUB.md
echo.
pause
