#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  Atención Dgtal · Bajar los cambios desde GitHub
#  (otra computadora tuya, o los de un compañero de equipo)
#  Uso:   bash actualizar.sh
#  Guía completa: GITHUB.md
# ═══════════════════════════════════════════════════════════════
set -euo pipefail
VERDE='\033[0;32m'; ROJO='\033[0;31m'; AMAR='\033[1;33m'; NEGR='\033[1m'; RESET='\033[0m'

command -v git >/dev/null 2>&1 || { printf "${ROJO}✘ Git no está instalado.${RESET}\n"; exit 1; }
[ -d .git ] || { printf "${ROJO}✘ Este proyecto aún no está en Git. La primera vez se descarga completo con:${RESET}\n"; printf "  git clone <URL_del_repositorio>   (GITHUB.md, apartado 7)\n"; exit 1; }
git remote get-url origin >/dev/null 2>&1 || { printf "${ROJO}✘ Sin repositorio conectado. Ejecuta: bash publicar_github.sh${RESET}\n"; exit 1; }

STASH=0
if [ -n "$(git status --porcelain)" ]; then
  git stash push -u -m "cambios locales antes de actualizar" >/dev/null
  STASH=1
  printf "${AMAR}• Tus cambios sin guardar se protegieron temporalmente; se restaurarán al final.${RESET}\n"
fi

printf "${NEGR}Descargando cambios desde GitHub…${RESET}\n"
if ! git pull --no-rebase origin main; then
  printf "${ROJO}✘ No se pudo combinar.${RESET} Revisa GITHUB.md (apartado 11: conflictos).\n"
  printf "  Si el mensaje habla de conflictos: abre los archivos afectados, busca ${NEGR}<<<<<<<${RESET}, decide qué versión queda y borra las marcas.\n"
  printf "  Para dejar el proyecto como estaba antes de este intento: ${NEGR}git merge --abort${RESET}\n"
  [ "$STASH" = "1" ] && printf "  Tus cambios siguen a salvo: se listan con ${NEGR}git stash list${RESET} y se recuperan con ${NEGR}git stash pop${RESET}.\n"
  exit 1
fi
printf "${VERDE}✔ Proyecto actualizado a la última versión publicada.${RESET}\n"

if [ "$STASH" = "1" ]; then
  if git stash pop; then
    printf "${VERDE}✔ Tus cambios locales fueron restaurados.${RESET}\n"
  else
    printf "${AMAR}• Tus cambios se restauraron pero chocan con lo descargado: busca las marcas${RESET}\n"
    printf "  ${AMAR}<<<<<<< en los archivos afectados, decide qué versión queda y termina con:${RESET}\n"
    printf "    git add -A && git commit -m \"resuelto conflicto\" && bash sincronizar.sh\n"
  fi
fi
