"""
Atención Dgtal — verificador de instalación.

Ejecuta una batería de comprobaciones en 6 fases y reporta si el
proyecto quedó listo para usarse en esta máquina:

    1/6  Versión de Python (>= 3.10)
    2/6  Dependencias externas (flet, openai, python-dotenv)
    3/6  Importación de los 4 niveles de la aplicación
    4/6  Configuración (.env, modo GPT real o MODO DEMO)
    5/6  Base de datos SQLite (creación y esquema)
    6/6  Prueba de humo: el enjambre completo atiende un chat y cierra una venta

Uso:
    python verificar.py

Salida: lista de resultados con ✅/⚠️/❌ y código de salida
        0 = instalación completa, 1 = hay problemas que resolver.
"""
from __future__ import annotations

import os
import sys
import tempfile
import traceback
from pathlib import Path

# Asegura que `app/` sea importable aunque se llame desde otra carpeta.
RAIZ = Path(__file__).resolve().parent
os.chdir(RAIZ)
if str(RAIZ) not in sys.path:
    sys.path.insert(0, str(RAIZ))

# Carga .env (si existe) ANTES de leer variables de entorno.
try:
    from dotenv import load_dotenv

    load_dotenv(RAIZ / ".env")
except Exception:
    pass

VERDE, AMAR, ROJO, RESET, NEGRITA = "\033[92m", "\033[93m", "\033[91m", "\033[0m", "\033[1m"
if os.name == "nt" or not sys.stdout.isatty():
    VERDE = AMAR = ROJO = RESET = NEGRITA = ""  # consolas sin soporte de color

OK = f"{VERDE}✅{RESET}"
AVISO = f"{AMAR}⚠️ {RESET}"
MAL = f"{ROJO}❌{RESET}"

_errores: list[str] = []
_avisos: list[str] = []


def ok(msg: str) -> None:
    print(f"   {OK}  {msg}")


def aviso(msg: str) -> None:
    print(f"   {AVISO}  {msg}")
    _avisos.append(msg)


def mal(msg: str) -> None:
    print(f"   {MAL}  {msg}")
    _errores.append(msg)


def fase(n: int, titulo: str) -> None:
    print(f"\n{NEGRITA}[{n}/6] {titulo}{RESET}")


# ═══════════════════════════════════════════════════════════════════════════
def main() -> int:
    print(f"{NEGRITA}{'═' * 62}{RESET}")
    print(f"{NEGRITA}  Atención Dgtal — Verificación de instalación{RESET}")
    try:
        _v = (RAIZ / "VERSION").read_text(encoding="utf-8").strip()
        print(f"{NEGRITA}  versión del proyecto: v{_v}{RESET}")
    except Exception:
        pass
    print(f"{NEGRITA}{'═' * 62}{RESET}")

    # ── 1/6 Python ──────────────────────────────────────────────────────────
    fase(1, "Versión de Python")
    v = sys.version_info
    print(f"   Interprete : {sys.executable}")
    print(f"   Versión    : {v.major}.{v.minor}.{v.micro} ({sys.platform})")
    if (v.major, v.minor) >= (3, 10):
        ok(f"Python {v.major}.{v.minor} cumple el requisito (>= 3.10)")
    else:
        mal(f"Se requiere Python 3.10 o superior y hay {v.major}.{v.minor}. Instálalo desde https://www.python.org/downloads/")

    # ── 2/6 Dependencias ────────────────────────────────────────────────────
    fase(2, "Dependencias externas")
    for nombre_pkg, import_name in (
        ("flet", "flet"),
        ("openai", "openai"),
        ("python-dotenv", "dotenv"),
    ):
        try:
            mod = __import__(import_name)
            version = getattr(mod, "__version__", "?")
            ok(f"{nombre_pkg:<14} v{version}")
        except Exception as e:
            mal(f"{nombre_pkg} NO está instalado ({e}). Ejecuta: pip install -r requirements.txt")

    # ── 3/6 Importación de módulos propios ─────────────────────────────────
    fase(3, "Módulos de la aplicación (4 niveles)")
    modulos = [
        ("Nivel 1 · Núcleo      ", "app.config"),
        ("Nivel 1 · Modelos      ", "app.core.models"),
        ("Nivel 1 · Enumeraciones", "app.core.enums"),
        ("Nivel 2 · Servicios    ", "app.services.calificador"),
        ("Nivel 2 · Persistencia ", "app.services.db"),
        ("Nivel 2 · Respaldo     ", "app.services.respaldo"),
        ("Nivel 3 · Enjambre     ", "app.swarm.enjambre"),
        ("Nivel 3 · Cliente LLM  ", "app.swarm.llm"),
        ("Nivel 4 · UI Shell     ", "app.ui.shell"),
        ("Nivel 4 · Micro app chat", "app.ui.micro_app_chat"),
        ("Nivel 4 · Micro app bandeja", "app.ui.micro_app_bandeja"),
        ("Nivel 4 · Micro app ajustes", "app.ui.micro_app_ajustes"),
    ]
    for etiqueta, nombre in modulos:
        try:
            __import__(nombre)
            ok(f"{etiqueta} {nombre}")
        except Exception as e:
            mal(f"{etiqueta} {nombre} → {type(e).__name__}: {e}")

    # ── 4/6 Configuración ───────────────────────────────────────────────────
    fase(4, "Configuración (.env)")
    tiene_env = (RAIZ / ".env").exists()
    if tiene_env:
        ok(f"Archivo .env encontrado: {RAIZ / '.env'}")
    else:
        aviso("No hay archivo .env. Se usarán los valores por defecto. "
              "Crea uno con:  cp .env.example .env  (Linux/Mac)  ó  copy .env.example .env  (Windows)")

    clave = os.getenv("OPENAI_API_KEY", "").strip()
    modelo = os.getenv("ADG_MODELO", "gpt-4o-mini")
    if clave:
        ok(f"OPENAI_API_KEY configurada → el closer usará GPT real ({modelo})")
        ok("La clave no se muestra por seguridad ✋")
    else:
        aviso("OPENAI_API_KEY vacía → el sistema arrancará en MODO DEMO con el simulador local "
              "(sin costo, 100% funcional). Puedes agregar la clave más tarde en el .env")

    # ── 5/6 SQLite ──────────────────────────────────────────────────────────
    fase(5, "Base de datos SQLite")
    try:
        os.environ["ADG_DB_PATH"] = os.path.join(tempfile.mkdtemp(prefix="adg_verif_"), "verif.db")
        from app.config import RUBROS, ConfigGlobal
        from app.services.db import Repositorio

        config = ConfigGlobal()
        repo = Repositorio(config.db_path)
        ok(f"Esquema creado sin errores en BD temporal: {config.db_path}")
        ok(f"Catálogo multi-industria: {', '.join(RUBROS.keys())}")
    except Exception as e:
        mal(f"No se pudo crear la base SQLite → {type(e).__name__}: {e}")
        traceback.print_exc()

    # ── 6/6 Prueba de humo del enjambre ─────────────────────────────────────
    fase(6, "Prueba de humo: enjambre completo (chat real simulado)")
    try:
        from app.core.enums import AutorMensaje, EstadoConversacion
        from app.services.agenda import opciones_disponibles
        from app.services.idioma import detectar_idioma, normalizar
        from app.swarm.enjambre import Enjambre

        # a) Detección de idioma ES/PT
        es_ok = detectar_idioma("buenas tardes, como va todo").value == "ES"
        pt_ok = detectar_idioma("bom dia, quero saber o preço").value == "PT"
        ok("Detección de idioma ES/PT") if es_ok and pt_ok else mal("Detección de idioma falló")

        # b) Normalización de argot local
        texto_limpio, argot = normalizar("xq quiero info del plan vc")
        ok(f"Argot normalizado (xq→porque, vc→você): detectados {argot}") if argot else aviso("Argot no detectado en la frase de prueba")

        # c) Agenda: slots disponibles
        slots = opciones_disponibles(repo, config.capacidad_por_franja, n=2)
        ok(f"Agenda interna genera {len(slots)} horarios con capacidad {config.capacidad_por_franja}/franja") if slots else mal("La agenda no generó horarios")

        # d) Enjambre: ciclo de vida completo de una venta
        os.environ["ADG_DB_PATH"] = os.path.join(tempfile.mkdtemp(prefix="adg_verif_"), "smoke.db")
        config_smoke = ConfigGlobal(api_key="")  # fuerza simulador: prueba sin red ni tokens
        repo_smoke = Repositorio(config_smoke.db_path)
        enjambre = Enjambre(config_smoke, repo_smoke)
        ok(f"Enjambre armado con {len(enjambre.agentes)} micro-agentes: "
           + ", ".join(a.nombre for a in enjambre.agentes))

        cliente = repo_smoke.obtener_o_crear_cliente("04140000000", "Cliente de Prueba")
        conv = repo_smoke.crear_conversacion(cliente.id, "ecommerce")

        r1 = _turno(repo_smoke, enjambre, conv,
                    "Quiero los audifonos TWS Pro, cuanto vale? los necesito hoy mismo, "
                    "mi numero es 04141234567, llamame whatsapp")
        if r1["respuesta"]:
            ok(f"Turno 1 respondido por [{r1['agente']}] → score {r1['score']} "
               f"({r1['temperatura']}), acción: {r1['accion']}")
        else:
            mal("El enjambre no generó respuesta al primer mensaje")

        conv2 = repo_smoke.obtener_conversacion(conv.id)
        if conv2.estado == EstadoConversacion.CITA_PROPUESTA:
            ok(f"Lead CALIENTE detectado → la IA propuso agenda automáticamente ({conv2.estado.value})")
        else:
            aviso(f"Estado tras turno 1: {conv2.estado.value} (esperado: CITA_PROPUESTA)")

        r2 = _turno(repo_smoke, enjambre, conv, "dale, la primera")
        conv3 = repo_smoke.obtener_conversacion(conv.id)
        ventas = repo_smoke.listar_ventas()
        if conv3.estado == EstadoConversacion.AGENDADA and ventas:
            ok(f"Venta cerrada 100% por IA → cita AGENDADA, venta registrada (canal {ventas[0].canal})")
        else:
            mal(f"Cierre automático falló: estado={conv3.estado.value}, ventas={len(ventas)}")

        # e) Derivación al humano
        r3 = _turno(repo_smoke, enjambre, conv, "ok, pero ahora quiero hablar con una persona")
        conv4 = repo_smoke.obtener_conversacion(conv.id)
        if conv4.estado == EstadoConversacion.DERIVADA_HUMANO:
            ok("Derivación al operador humano funciona (bandeja lista para usarse)")
        else:
            aviso(f"Derivación devolvió estado {conv4.estado.value} (esperado: DERIVADA_HUMANO)")

    except Exception as e:
        mal(f"Prueba de humo falló → {type(e).__name__}: {e}")
        traceback.print_exc()

    # ── Resumen ─────────────────────────────────────────────────────────────
    print(f"\n{NEGRITA}{'═' * 62}{RESET}")
    if not _errores:
        print(f"{VERDE}{NEGRITA}  ✅ INSTALACIÓN COMPLETA — Atención Dgtal está listo para usarse{RESET}")
        print(f"{NEGRITA}{'═' * 62}{RESET}")
        print("\n  Próximos pasos:")
        print("    • Escritorio : python main.py")
        print("    • Navegador  : python main.py --web   → http://localhost:8550")
        print("    • Tests      : python -m unittest discover -s tests -v")
        if _avisos:
            print(f"\n  {len(_avisos)} aviso(s) informativo(s) arriba (no bloquean el uso).")
        return 0
    else:
        print(f"{ROJO}{NEGRITA}  ❌ INSTALACIÓN INCOMPLETA — {len(_errores)} problema(s) detectado(s){RESET}")
        print(f"{NEGRITA}{'═' * 62}{RESET}")
        print("\n  Revisa los errores marcados con ❌ arriba. Lo más común:")
        print("    1. Falta de dependencias  →  pip install -r requirements.txt")
        print("    2. Python antiguo         →  actualiza a 3.10 o superior")
        print("    3. Copia incompleta       →  vuelve a descomprimir el ZIP")
        print("\n  Guía detallada: INSTALACION.md (sección «Solución de problemas»)")
        return 1


def _turno(repo, enjambre, conv, texto: str) -> dict:
    """Registra el mensaje del cliente y lo pasa por el enjambre."""
    from app.core.enums import AutorMensaje

    repo.agregar_mensaje(conv.id, AutorMensaje.CLIENTE, texto)
    return enjambre.procesar_mensaje_cliente(conv, texto)


if __name__ == "__main__":
    sys.exit(main())
