#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  Atención Dgtal · Subir tus cambios a GitHub (flujo diario)
#  Uso:   bash sincronizar.sh "qué cambiaste"
#  Ej.:   bash sincronizar.sh "mejora del calificador de leads"
#  Guía completa: GITHUB.md
# ═══════════════════════════════════════════════════════════════
set -euo pipefail
VERDE='\033[0;32m'; ROJO='\033[0;31m'; AMAR='\033[1;33m'; NEGR='\033[1m'; RESET='\033[0m'

command -v git >/dev/null 2>&1 || { printf "${ROJO}✘ Git no está instalado.${RESET}\n"; exit 1; }
[ -d .git ] || { printf "${ROJO}✘ Este proyecto aún no está en Git. Ejecuta primero: bash publicar_github.sh${RESET}\n"; exit 1; }
git remote get-url origin >/dev/null 2>&1 || { printf "${ROJO}✘ Sin repositorio conectado. Ejecuta: bash publicar_github.sh${RESET}\n"; exit 1; }

# ¿Hay un conflicto de fusión sin resolver? No se permite cometer marcas <<<<<<<
if CONFLICTOS="$(git diff --name-only --diff-filter=U)" && [ -n "$CONFLICTOS" ]; then
  printf "${ROJO}✘ Hay un conflicto de fusión sin resolver en:${RESET}\n"
  printf '%s\n' "$CONFLICTOS" | sed 's/^/    • /'
  printf "  Abre cada archivo, busca la marca ${NEGR}<<<<<<<${RESET}, decide qué versión queda y borra las marcas.\n"
  printf "  Después cierra el conflicto con: ${NEGR}git add -A && git commit${RESET} y lanza ${NEGR}bash sincronizar.sh${RESET}.\n"
  exit 1
fi

MENSAJE="${*:-}"
[ -n "$MENSAJE" ] || MENSAJE="Actualización $(date '+%Y-%m-%d %H:%M')"

git add -A
if git diff --cached --quiet; then
  # Sin cambios nuevos: ¿quedaron commits guardados sin subir de un intento anterior?
  PENDIENTES="$(git log origin/main..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')"
  if [ "${PENDIENTES:-0}" -gt 0 ]; then
    printf "${AMAR}• No hay cambios nuevos, pero hay ${NEGR}%s commit(s) guardados sin subir${RESET}${AMAR}. Enviando…${RESET}\n" "$PENDIENTES"
    if git push; then
      printf "${VERDE}✔ Sincronizado con GitHub.${RESET}\n"
    else
      printf "${ROJO}✘ No se pudo enviar.${RESET} Ejecuta ${NEGR}bash actualizar.sh${RESET} y vuelve a lanzar ${NEGR}bash sincronizar.sh${RESET}.\n"
      exit 1
    fi
  else
    printf "${AMAR}• No hay cambios que enviar: GitHub ya está al día.${RESET}\n"
  fi
  exit 0
fi

git commit -m "$MENSAJE" >/dev/null
printf "${NEGR}Guardado en el historial:${RESET} %s\n" "$MENSAJE"

if git push; then
  printf "${VERDE}✔ Sincronizado con GitHub${RESET} (%s → %s)\n" \
    "$(git log --oneline -1 | cut -d' ' -f1)" "$(git remote get-url origin)"
else
  printf "${ROJO}✘ No se pudo enviar.${RESET} Lo normal es que haya cambios nuevos en GitHub que no tienes tú.\n"
  printf "  Solución: ejecuta ${NEGR}bash actualizar.sh${RESET} y vuelve a lanzar ${NEGR}bash sincronizar.sh${RESET}.\n"
  exit 1
fi
