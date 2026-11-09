"""
Atención Dgtal — ASISTENTE DE RESPALDO DE CONFIGURACIÓN (v3.0)
==============================================================
Guía paso a paso pensada para el usuario nuevo: crea, consulta y restaura
respaldos respondiendo preguntas simples (Enter para aceptar lo sugerido).

Uso:
    python asistente_respaldo.py          # Linux/Mac y Windows
    respaldar.bat                          # doble clic en Windows
    ./respaldar.sh                         # Linux/Mac
"""
from __future__ import annotations

import sys
from pathlib import Path

# Permite correr el asistente desde cualquier carpeta
RAIZ = Path(__file__).resolve().parent
sys.path.insert(0, str(RAIZ))

from app.config import ConfigGlobal  # noqa: E402
from app.services.respaldo import (  # noqa: E402
    carpeta_respaldos,
    crear_respaldo,
    listar_respaldos,
    restaurar_respaldo,
)

NEGR = "\033[1m" if sys.stdout.isatty() else ""
VERDE = "\033[0;32m" if sys.stdout.isatty() else ""
AMAR = "\033[1;33m" if sys.stdout.isatty() else ""
ROJO = "\033[0;31m" if sys.stdout.isatty() else ""
RESET = "\033[0m" if sys.stdout.isatty() else ""


def preguntar_si(pregunta: str, defecto: bool = True) -> bool:
    sugerencia = "S/n" if defecto else "s/N"
    respuesta = input(f"  {pregunta} [{sugerencia}]: ").strip().lower()
    if not respuesta:
        return defecto
    return respuesta in ("s", "si", "sí", "y", "yes")


def _flujo_crear() -> None:
    print(f"\n{NEGR}── Crear un respaldo ──{RESET}")
    print("Elige qué guardar (Enter para aceptar lo sugerido):")
    incluir_db = preguntar_si("¿Guardar la base de datos? (clientes, chats, citas, ventas)", True)
    incluir_env = preguntar_si("¿Guardar la configuración? (.env con tu API key)", True)
    incluir_rubros = preguntar_si("¿Guardar el catálogo de rubros?", True)

    if not (incluir_db or incluir_env or incluir_rubros):
        print(f"{AMAR}• No elegiste nada que guardar. No se creó ningún respaldo.{RESET}")
        return

    ruta = crear_respaldo(
        incluir_db=incluir_db,
        incluir_env=incluir_env,
        incluir_rubros=incluir_rubros,
        config=ConfigGlobal(),
    )
    tamaño_kb = ruta.stat().st_size / 1024
    print(f"\n{VERDE}✔ Respaldo creado:{RESET} {ruta}")
    print(f"  Tamaño: {tamaño_kb:.1f} KB · Ubicación: carpeta '{carpeta_respaldos().name}' del proyecto")
    print("  Consejo: copia este ZIP a una memoria USB o a la nube cada tanto.")


def _flujo_ver() -> None:
    print(f"\n{NEGR}── Respaldos guardados ──{RESET}")
    carpeta = carpeta_respaldos()
    lista = listar_respaldos()
    if not lista:
        print(f"{AMAR}• Todavía no hay respaldos en {carpeta}{RESET}")
        print("  Usa la opción 1 para crear el primero.")
        return
    print(f"  Carpeta: {carpeta}\n")
    for i, r in enumerate(lista, 1):
        if r["corrupto"]:
            print(f"  {i}. {r['nombre']} — {ROJO}corrupto o incompleto{RESET} ({r['tamaño_kb']} KB)")
            continue
        partes = []
        if r["incluye"].get("base_datos"):
            partes.append("base de datos")
        if r["incluye"].get("config"):
            partes.append("config")
        if r["incluye"].get("rubros"):
            partes.append("rubros")
        print(f"  {i}. {r['nombre']}")
        print(f"     creado: {r['creado'] or '?'} · v{r['version_app'] or '?'} · "
              f"{r['tamaño_kb']} KB · incluye: {', '.join(partes) or '—'}")


def _flujo_restaurar() -> None:
    print(f"\n{NEGR}── Restaurar un respaldo ──{RESET}")
    lista = listar_respaldos()
    lista_valida = [r for r in lista if not r["corrupto"]]
    if not lista_valida:
        print(f"{AMAR}• No hay respaldos válidos para restaurar.{RESET}")
        return

    print("  ¿Cuál respaldo quieres restaurar?")
    for i, r in enumerate(lista_valida, 1):
        print(f"   {i}. {r['nombre']}  (creado {r['creado'] or '?'} · v{r['version_app'] or '?'})")
    eleccion = input("  Número (Enter para cancelar): ").strip()
    if not eleccion.isdigit() or not (1 <= int(eleccion) <= len(lista_valida)):
        print(f"{AMAR}• Cancelado.{RESET}")
        return
    elegido = lista_valida[int(eleccion) - 1]

    print(f"\n  El respaldo incluye: ", end="")
    partes = [n for n, k in (("base de datos", "base_datos"), ("configuración", "config"),
                             ("rubros", "rubros")) if elegido["incluye"].get(k)]
    print(", ".join(partes) or "—")

    restaurar_db = "base de datos" in partes and preguntar_si("  ¿Restaurar la base de datos?", True)
    restaurar_env = "configuración" in partes and preguntar_si("  ¿Restaurar la configuración (.env)?", True)
    restaurar_rubros = "rubros" in partes and preguntar_si("  ¿Restaurar el catálogo de rubros?", True)
    if not (restaurar_db or restaurar_env or restaurar_rubros):
        print(f"{AMAR}• No elegiste nada que restaurar.{RESET}")
        return

    if restaurar_db:
        print(f"{AMAR}  ⚠ Importante: cierra la app de Atención Dgtal antes de restaurar la base{RESET}")
        if not preguntar_si("    ¿La app está cerrada y quieres continuar?", False):
            print(f"{AMAR}• Cancelado por seguridad.{RESET}")
            return

    try:
        resumen = restaurar_respaldo(
            elegido["ruta"],
            restaurar_db=restaurar_db,
            restaurar_env=restaurar_env,
            restaurar_rubros=restaurar_rubros,
            config=ConfigGlobal(),
        )
    except Exception as error:  # noqa: BLE001
        print(f"{ROJO}✘ No se pudo restaurar: {error}{RESET}")
        return

    print()
    for item in resumen["restaurado"]:
        print(f"{VERDE}✔ Restaurado:{RESET} {item}")
    for item in resumen["omitido"]:
        print(f"{AMAR}• Omitido:{RESET} {item}")
    if resumen.get("env_previo"):
        print(f"  Tu configuración anterior se conservó en: {resumen['env_previo']}")
    if any("rubros" in item for item in resumen["restaurado"]):
        print("  El catálogo restaurado se activará la próxima vez que abras la app.")


def main() -> None:
    config = ConfigGlobal()
    print()
    print(f"{NEGR}╔══════════════════════════════════════════════════╗{RESET}")
    print(f"{NEGR}║  Atención Dgtal v{config.version} · Asistente de respaldo  ║{RESET}")
    print(f"{NEGR}╚══════════════════════════════════════════════════╝{RESET}")

    while True:
        print(f"\n{NEGR}¿Qué quieres hacer?{RESET}")
        print("  1) Crear un respaldo de configuración")
        print("  2) Ver los respaldos guardados")
        print("  3) Restaurar un respaldo")
        print("  0) Salir")
        opcion = input("  Opción [1]: ").strip() or "1"

        if opcion == "1":
            _flujo_crear()
        elif opcion == "2":
            _flujo_ver()
        elif opcion == "3":
            _flujo_restaurar()
        elif opcion in ("0", "q", "salir"):
            print(f"\n{VERDE}¡Listo! Tus datos están a salvo. 👋{RESET}")
            return
        else:
            print(f"{AMAR}• Opción no válida: escribe 1, 2, 3 o 0.{RESET}")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{AMAR}• Cancelado por el usuario.{RESET}")
        sys.exit(130)
