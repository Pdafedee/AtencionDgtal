#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  Atención Dgtal · Publicar el proyecto en GitHub (1ª vez)
#  Uso:   bash publicar_github.sh [URL_del_repositorio]
#  Ej.:   bash publicar_github.sh https://github.com/usuario/atencion-dgtal.git
#  Guía completa: GITHUB.md
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

VERDE='\033[0;32m'; AMAR='\033[1;33m'; ROJO='\033[0;31m'; CYAN='\033[0;36m'; NEGR='\033[1m'; RESET='\033[0m'
paso(){ printf "${CYAN}${NEGR}[%s/6]${RESET} %s\n" "$1" "$2"; }
ok(){ printf "    ${VERDE}✔${RESET} %s\n" "$1"; }
aviso(){ printf "    ${AMAR}•${RESET} %s\n" "$1"; }
err(){ printf "    ${ROJO}✘ %s${RESET}\n" "$1" >&2; exit 1; }

printf "\n${NEGR}═══ Atención Dgtal · Publicar en GitHub ═══${RESET}\n\n"

# ── 1 · Git instalado ──────────────────────────────────────────
paso 1 "Comprobando que Git está instalado"
command -v git >/dev/null 2>&1 || err "Git no está instalado. Descárgalo de https://git-scm.com/downloads y vuelve a ejecutar."
ok "$(git --version)"

# ── 2 · Identidad (solo la primera vez en esta máquina) ───────
if [ -z "$(git config user.name || true)" ] || [ -z "$(git config user.email || true)" ]; then
  printf "    ${AMAR}Git necesita tu nombre y correo para firmar tus cambios (se configura una sola vez).${RESET}\n"
  read -rp "    Tu nombre y apellido: " _NOMBRE
  read -rp "    Tu correo electrónico: " _CORREO
  [ -n "$_NOMBRE" ] && [ -n "$_CORREO" ] || err "Nombre y correo son obligatorios."
  git config --global user.name "$_NOMBRE"
  git config --global user.email "$_CORREO"
  ok "Identidad guardada: $_NOMBRE <$_CORREO>"
else
  ok "Identidad: $(git config user.name) <$(git config user.email)>"
fi

# ── 3 · Repositorio local ──────────────────────────────────────
paso 2 "Inicializando el repositorio local"
if [ -d .git ]; then
  ok "Ya existía: no se toca nada"
else
  if git init -b main >/dev/null 2>&1; then ok "Creado, rama principal: main"
  else git init >/dev/null && git branch -M main && ok "Creado, rama principal: main"; fi
fi

# ── 4 · Primera foto del proyecto (commit) ────────────────────
paso 3 "Guardando la primera versión del proyecto"
git add -A
if git diff --cached --quiet; then
  ok "No hay cambios nuevos que guardar"
else
  git commit -m "Primera version de Atencion Dgtal" >/dev/null
  ok "Versión guardada en el historial local"
fi

# ── 5 · Conectar con GitHub ────────────────────────────────────
paso 4 "Conectando con tu repositorio de GitHub"
URL="${1:-}"
if [ -z "$URL" ]; then
  printf "    ${AMAR}Si aún no creaste el repositorio: https://github.com/new (guía en GITHUB.md, apartado 3).${RESET}\n"
  read -rp "    Pega la dirección HTTPS del repositorio (ej. https://github.com/tu-usuario/atencion-dgtal.git): " URL
fi
[ -n "$URL" ] || err "Necesito la dirección del repositorio."
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$URL"
else
  git remote add origin "$URL"
fi
ok "Conectado a $URL"

# ── 6 · Publicar ────────────────────────────────────────────────
paso 5 "Subiendo el proyecto a GitHub"
aviso "GitHub pedirá tu usuario y una contraseña: la contraseña es tu Personal Access Token (GITHUB.md, apartado 5)."
if git push -u origin main; then
  ok "¡Publicado! Tu código ya está en GitHub"
else
  err "No se pudo subir. Causas típicas:
        (1) token incorrecto → genera otro (GITHUB.md, apartado 5);
        (2) el repositorio ya tenía contenido → ejecuta 'git pull origin main --allow-unrelated-histories' y repite el push."
fi

paso 6 "Listo"
printf "\n  ${VERDE}${NEGR}Proyecto publicado.${RESET} A partir de ahora, con cada cambio que hagas:\n"
printf "    · ${NEGR}bash sincronizar.sh \"mensaje\"${RESET}  → sube tus cambios a GitHub\n"
printf "    · ${NEGR}bash actualizar.sh${RESET}             → baja los cambios hechos en otra máquina\n"
printf "  Guía completa: ${NEGR}GITHUB.md${RESET}\n\n"
