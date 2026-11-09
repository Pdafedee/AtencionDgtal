"""
Atención Dgtal — punto de entrada.

Uso:
    python main.py                 → app de escritorio (ventana nativa Flet)
    python main.py --web           → navegador en http://localhost:8550
    python main.py --web --port=9000
    python main.py --web --render=skwasm   → renderer SkWASM (más ligero;
        útil en navegadores donde CanvasKit vaya lento o falle)

Nota: Flet 1.x ya no incluye el renderer HTML — requiere un navegador
moderno con WebGL (Chrome/Edge ≥ 2021, Firefox ≥ 2021, Safari ≥ 15).
"""
from __future__ import annotations

import sys

import flet as ft

from app.ui.shell import main as shell_main


def main(page: ft.Page) -> None:
    shell_main(page)


def _arg(valor: str, defecto: str | None = None) -> str | None:
    """Lee un argumento de la forma --clave=valor."""
    for arg in sys.argv[1:]:
        if arg.startswith(f"--{valor}="):
            return arg.split("=", 1)[1]
    return defecto


if __name__ == "__main__":
    args = sys.argv[1:]
    modo_web = "--web" in args
    puerto = int(_arg("port", "8550") or 8550)

    if modo_web:
        renderer = (_arg("render") or "").lower()
        kwargs: dict = dict(view=ft.AppView.WEB_BROWSER, port=puerto)
        if renderer in ("skwasm", "wasm"):
            kwargs["web_renderer"] = ft.WebRenderer.SKWASM
        elif renderer in ("canvaskit", "canvas"):
            kwargs["web_renderer"] = ft.WebRenderer.CANVAS_KIT
        elif renderer == "auto":
            kwargs["web_renderer"] = ft.WebRenderer.AUTO
        # omisión → AUTO (Flet elige el mejor disponible)
        ft.run(main, **kwargs)
    else:
        ft.run(main)
