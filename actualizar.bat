@echo off
setlocal enabledelayedexpansion
title Atencion Dgtal - Actualizar desde GitHub

where git >nul 2>nul
if errorlevel 1 (echo [X] Git no esta instalado. & pause & exit /b 1)
if not exist .git (
  echo [X] Este proyecto aun no esta en Git. La primera vez se descarga completo con:
  echo     git clone URL_del_repositorio      - guia: GITHUB.md apartado 7
  pause
  exit /b 1
)
git remote get-url origin >nul 2>nul
if errorlevel 1 (
  echo [X] Sin repositorio conectado. Ejecuta primero: publicar_github.bat
  pause
  exit /b 1
)

rem -- Proteger cambios locales sin guardar --
set STASH=0
set PEND=0
for /f "usebackq delims=" %%i in (`git status --porcelain 2^>nul ^| find /c /v ""`) do set PEND=%%i
if not "%PEND%"=="0" (
  git stash push -u -m "cambios locales antes de actualizar" >nul
  set STASH=1
  echo [AVISO] Tus cambios sin guardar se protegieron y se restauraran al final.
)

echo Descargando cambios desde GitHub...
git pull --no-rebase origin main
if errorlevel 1 (
  echo [X] No se pudo actualizar. Si el mensaje habla de conflictos: GITHUB.md apartado 11.
  echo     Para dejar el proyecto como estaba: git merge --abort
  if "%STASH%"=="1" echo     Tus cambios siguen a salvo: se listan con "git stash list".
  pause
  exit /b 1
)
echo [OK] Proyecto actualizado a la ultima version publicada.

if "%STASH%"=="1" (
  git stash pop
  if errorlevel 1 (
    echo [AVISO] Tus cambios se restauraron pero chocan con lo descargado:
    echo     busca las marcas ^<^<^<^<^<^<^< en los archivos afectados, decide que version
    echo     queda, y termina con: git add -A ^&^& git commit -m "resuelto conflicto"
  ) else (
    echo [OK] Tus cambios locales fueron restaurados.
  )
)
pause
