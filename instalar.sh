#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#  Atención Dgtal — Instalador automático (Linux / macOS)
#
#  Uso:    bash instalar.sh
#  Qué hace:
#    1. Localiza un Python 3.10+ en el sistema
#    2. Crea el entorno virtual .venv (aislado del sistema)
#    3. Instala las dependencias (flet, openai, python-dotenv)
#    4. Crea tu .env personal desde .env.example (sin sobrescribir)
#    5. Verifica TODO el sistema con verificar.py
# ═══════════════════════════════════════════════════════════════════════
set -u
cd "$(dirname "$0")"

if [ -t 1 ]; then
  VERDE="\033[92m"; AMAR="\033[93m"; ROJO="\033[91m"; CIAN="\033[96m"; NEGR="\033[1m"; RESET="\033[0m"
else
  VERDE=""; AMAR=""; ROJO=""; CIAN=""; NEGR=""; RESET=""
fi

paso() { printf "${CIAN}${NEGR}→${RESET} ${1}\n"; }
exito() { printf "  ${VERDE}✅${RESET} ${1}\n"; }
fallo() { printf "  ${ROJO}❌${RESET} ${1}\n"; }

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Atención Dgtal · Instalador automático (Linux/Mac)     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
printf "Carpeta del proyecto: %s\n" "$(pwd)"

# ── Paso 1: localizar Python 3.10+ ──────────────────────────────────────
paso "Paso 1/5 · Buscando Python 3.10 o superior..."
PYTHON=""
for cand in python3.12 python3.11 python3.10 python3 python; do
  if command -v "$cand" >/dev/null 2>&1; then
    if "$cand" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' 2>/dev/null; then
      PYTHON="$cand"
      break
    fi
  fi
done

if [ -z "$PYTHON" ]; then
  fallo "No se encontró Python 3.10+."
  echo ""
  echo "   Instálalo y vuelve a ejecutar este script:"
  echo "     • Ubuntu/Debian : sudo apt install python3 python3-venv python3-pip"
  echo "     • Fedora        : sudo dnf install python3"
  echo "     • macOS (brew)  : brew install python"
  echo "     • Universal     : https://www.python.org/downloads/"
  exit 1
fi
exito "Encontrado: $PYTHON ($("$PYTHON" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")'))"

# ── Paso 2: entorno virtual ─────────────────────────────────────────────
paso "Paso 2/5 · Preparando entorno virtual (.venv)..."
if [ -d ".venv" ] && [ -x ".venv/bin/python" ]; then
  exito "Ya existía, se reutiliza."
else
  if ! "$PYTHON" -m venv .venv 2>/dev/null; then
    fallo "No se pudo crear el entorno virtual (¿falta python3-venv?)."
    echo "   En Ubuntu/Debian ejecuta: sudo apt install python3-venv"
    exit 1
  fi
  exito "Entorno .venv creado."
fi
# shellcheck disable=SC1091
source .venv/bin/activate

# ── Paso 3: dependencias ────────────────────────────────────────────────
paso "Paso 3/5 · Instalando dependencias (puede tardar 1-3 minutos)..."
python -m pip install --upgrade pip --quiet
if python -m pip install -r requirements.txt --quiet; then
  exito "flet + openai + python-dotenv instalados."
else
  fallo "pip no pudo instalar las dependencias."
  echo "   Revisa tu conexión a internet o proxy y vuelve a intentar:"
  echo "     python -m pip install -r requirements.txt"
  exit 1
fi

# ── Paso 4: configuración personal ──────────────────────────────────────
paso "Paso 4/5 · Configuración (.env)..."
if [ -f ".env" ]; then
  exito ".env ya existe, se conserva tu configuración."
else
  cp .env.example .env
  exito ".env creado desde .env.example."
  echo "   ${AMAR}ℹ Sin clave OpenAI funciona en MODO DEMO (simulador local, costo 0).${RESET}"
  echo "   ${AMAR}  Para GPT real edita .env y llena OPENAI_API_KEY.${RESET}"
fi

# ── Paso 5: verificación completa ───────────────────────────────────────
paso "Paso 5/5 · Verificando la instalación..."
echo ""
python verificar.py
RESULTADO=$?
echo ""

if [ "$RESULTADO" -eq 0 ]; then
  echo "${VERDE}╔══════════════════════════════════════════════════════════╗${RESET}"
  echo "${VERDE}║   🎉  INSTALACIÓN TERMINADA — todo listo para usarse      ║${RESET}"
  echo "${VERDE}╚══════════════════════════════════════════════════════════╝${RESET}"
  echo ""
  echo "   Para arrancar la aplicación:"
  echo "     ${NEGR}bash ejecutar.sh${RESET}              # app de escritorio"
  echo "     ${NEGR}bash ejecutar.sh --web${RESET}        # navegador: http://localhost:8550"
  echo ""
  echo "   (estos comandos activan el .venv solos; no necesitas nada más)"
else
  echo "${ROJO}La verificación detectó problemas. Revisa los ❌ de arriba${RESET}"
  echo "o consulta INSTALACION.md (sección «Solución de problemas»)."
fi
exit "$RESULTADO"
