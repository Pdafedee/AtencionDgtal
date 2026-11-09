@echo off
setlocal enabledelayedexpansion
title Atencion Dgtal - Sincronizar cambios

where git >nul 2>nul
if errorlevel 1 (echo [X] Git no esta instalado. & pause & exit /b 1)
if not exist .git (
  echo [X] Este proyecto aun no esta en Git. Ejecuta primero: publicar_github.bat
  pause
  exit /b 1
)
git remote get-url origin >nul 2>nul
if errorlevel 1 (
  echo [X] Sin repositorio conectado. Ejecuta primero: publicar_github.bat
  pause
  exit /b 1
)

rem -- Conflicto de fusion sin resolver: no se permiten marcas ^<^<^<^<^<^<^< --
set CONF=0
for /f "usebackq delims=" %%i in (`git diff --name-only --diff-filter=U 2^>nul ^| find /c /v ""`) do set CONF=%%i
if not "%CONF%"=="0" (
  echo [X] Hay un conflicto de fusion sin resolver en %CONF% archivo^(s^):
  git diff --name-only --diff-filter=U
  echo     Abre cada archivo, busca la marca ^<^<^<^<^<^<^<, decide que version queda y borra las marcas.
  echo     Despues cierra el conflicto con: git add -A ^&^& git commit
  echo     y finalmente lanza: sincronizar.bat
  pause
  exit /b 1
)

set MSG=%*
if "%MSG%"=="" set /p MSG=  Escribe que cambiaste y pulsa ENTER, o solo ENTER para mensaje automatico:
if "%MSG%"=="" set MSG=Actualizacion %date% %time%

git add -A
set CAMBIOS=0
for /f "usebackq delims=" %%i in (`git status --porcelain 2^>nul ^| find /c /v ""`) do set CAMBIOS=%%i
if "%CAMBIOS%"=="0" (
  set PENDI=0
  for /f "usebackq delims=" %%i in (`git log origin/main..HEAD --oneline 2^>nul ^| find /c /v ""`) do set PENDI=%%i
  if "!PENDI!"=="0" (
    echo GitHub ya esta al dia: no hay cambios que enviar.
    pause
    exit /b 0
  )
  echo No hay cambios nuevos, pero hay !PENDI! commit^(s^) guardados sin subir. Enviando...
  git push
  if errorlevel 1 (
    echo [X] No se pudo enviar. Ejecuta primero actualizar.bat y reintenta sincronizar.bat
    pause
    exit /b 1
  )
  echo [OK] Sincronizado con GitHub.
  pause
  exit /b 0
)

git commit -m "%MSG%" >nul
echo Guardado en el historial: "%MSG%"
echo Enviando a GitHub...
git push
if errorlevel 1 (
  echo [X] No se pudo enviar. Lo normal es que haya cambios nuevos en GitHub:
  echo     ejecuta primero actualizar.bat y vuelve a lanzar sincronizar.bat
  pause
  exit /b 1
)
echo [OK] Sincronizado con GitHub.
pause
