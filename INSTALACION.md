# 📦 Guía de instalación y uso — Atención Dgtal

Esta guía explica **cómo exportar, instalar y arrancar** el sistema de atención
automatizada en cualquier computadora: Windows, Linux o macOS, en modo
**escritorio** (ventana nativa) o **web** (navegador). Al final hay una tabla de
solución de problemas con los errores más comunes.

> **Tiempo total estimado:** 5–8 minutos (descarga e instalación incluidas).
> **No necesitas** instalar bases de datos, servidores ni cuentas externas:
> SQLite viene integrado en Python y el sistema funciona sin OpenAI (modo demo).
> ¿Ya instalado? → **MANUAL.md** (uso paso a paso). ¿Lo quieres como un solo
> `.exe` de Windows? → sección 7 de esta guía.

---

## 1. Requisitos previos

| Requisito | Mínimo | Notas |
|---|---|---|
| Sistema operativo | Windows 10/11, Ubuntu 20.04+, macOS 12+ | también corre en Raspberry Pi OS 64-bit |
| Python | **3.10 o superior** | imprescindible; en Windows marca *«Add python.exe to PATH»* |
| Espacio en disco | ~500 MB | el entorno virtual pesa ≈ 300 MB |
| RAM | 2 GB libres | 4 GB recomendados si usas GPT real + navegador |
| Internet | solo para instalar y (opcional) usar GPT | el modo demo funciona 100% sin red |
| Cuenta OpenAI | opcional | sin clave → simulador local de respaldo, costo $0 |

**Comprueba si ya tienes Python** abriendo una terminal (en Windows: `cmd` o
PowerShell) y escribiendo:

```bash
python3 --version     # Linux / macOS
python --version      # Windows
```

Si aparece `3.10` o mayor, continúa. Si no, descárgalo de
[python.org/downloads](https://www.python.org/downloads/).

---

## 2. Paso 0 — Exportar el proyecto

El proyecto se distribuye como **`AtencionDgtal.zip`**. Descomprímelo en una
carpeta de tu preferencia:

```bash
# Linux / macOS — descomprimir y entrar
unzip AtencionDgtal.zip -d atencion-dgtal
cd atencion-dgtal

# Windows (cmd) — descomprimir con el explorador o con:
tar -xf AtencionDgtal.zip
cd AtencionDgtal
```

> **Consejos de ubicación**
> - Elige una ruta **sin espacios ni acentos** si es posible
>   (`C:\proyectos\atencion-dgtal` mejor que `C:\Mis Documentos\¡Nuevo!`).
> - Evita carpetas sincronizadas en la nube (OneDrive/Dropbox): SQLite no
>   trabaja bien con archivos bloqueados por el sincronizador.

Estructura que verás dentro:

```
AtencionDgtal/
├── app/                  # código fuente (4 niveles: núcleo, servicios, enjambre, UI)
├── tests/                # suite de pruebas (42 tests)
├── main.py               # punto de entrada
├── VERSION               # versión actual (3.0.0)
├── instalar.sh / .bat    # ← instalador automático (opción A)
├── ejecutar.sh / .bat    # lanzador rápido (activa .venv y abre la app)
├── verificar.py          # chequeo de salud del sistema
├── MANUAL.md             # manual de usuario paso a paso
├── asistente_respaldo.py · respaldar.sh/.bat   # respaldos por consola (v3.0)
├── compilar_windows.bat · compilar_linux.sh    # crear el ejecutable (v3.0)
├── requirements.txt      # dependencias
├── .env.example          # plantilla de configuración
├── GITHUB.md             # guía: publicar en GitHub y sincronizar
├── publicar_github.sh/.bat · sincronizar.sh/.bat · actualizar.sh/.bat
└── README.md             # documentación técnica y de negocio
```

---

## 3. Opción A — Instalación automática (recomendada) ⚡

Un solo comando hace **todo**: entornos, dependencias, configuración y verificación.

**Linux / macOS** (dentro de la carpeta del proyecto):

```bash
bash instalar.sh
```

**Windows**: haz **doble clic** sobre `instalar.bat`
(o desde `cmd`: `instalar.bat`).

El instalador ejecuta 5 pasos y muestra el avance:

| Paso | Qué hace |
|---|---|
| 1/5 | Busca un Python 3.10+ instalado en el sistema |
| 2/5 | Crea el entorno virtual `.venv` (no toma tu Python global) |
| 3/5 | Instala `flet`, `openai` y `python-dotenv` con pip |
| 4/5 | Crea tu archivo `.env` personal desde `.env.example` (no sobrescribe) |
| 5/5 | Corre `verificar.py`: prueba Python, módulos, base de datos y **un chat real de punta a punta** (calificación → agenda → venta → derivación) |

Si el último bloque dice **✅ INSTALACIÓN COMPLETA**, salta a la
[sección 6 (Puesta en marcha)](#6-puesta-en-marcha-).

---

## 4. Opción B — Instalación manual (paso a paso) 🔧

Útil si prefieres controlar cada paso o el instalador automático falla.

### 4.1 Crear el entorno virtual

```bash
# Linux / macOS
python3 -m venv .venv
source .venv/bin/activate

# Windows (PowerShell)
python -m venv .venv
.venv\Scripts\Activate.ps1

# Windows (cmd)
python -m venv .venv
.venv\Scripts\activate.bat
```

Verás `(venv)` o `(.venv)` al inicio de la línea de tu terminal: las
instalaciones quedarán aisladas del resto del sistema.

> **PowerShell bloquea el activate?** Ejecuta una sola vez:
> `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`
> y vuelve a intentar el `Activate.ps1`. O usa la variante `cmd`.

### 4.2 Instalar dependencias

```bash
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

Son 3 paquetes: **flet** (interfaz), **openai** (IA) y **python-dotenv**
(configuración). Tarda 1–3 minutos.

### 4.3 Crear la configuración

```bash
# Linux / macOS
cp .env.example .env

# Windows
copy .env.example .env
```

Edita `.env` con cualquier editor de texto (tabla de variables en la
siguiente sección). Este paso es **opcional**: sin `.env` el sistema usa
valores por defecto y arranca en modo demo.

---

## 5. Configuración (`.env`)

| Variable | Obligatoria | Valor por defecto | Descripción |
|---|---|---|---|
| `OPENAI_API_KEY` | no | *(vacía)* | Clave de OpenAI. **Con clave** → el closer conversa con GPT real. **Sin clave** → simulador local (modo demo, costo 0) |
| `ADG_MODELO` | no | `gpt-4o-mini` | Modelo a usar cuando haya clave (`gpt-4o-mini`, `gpt-4o`, …) |
| `ADG_UMBRAL_CALIENTE` | no | `70` | Score ≥ este valor ⇒ lead CALIENTE (la IA agenda sola) |
| `ADG_UMBRAL_TIBIO` | no | `40` | Score ≥ este valor ⇒ lead TIBIO (el vendedor construye) |
| `ADG_DB_PATH` | no | `data/atencion_dgtal.db` | Ruta alternativa del archivo SQLite |

**¿Cuánto cuesta usar GPT real?** Solo los turnos del closer consumen tokens;
portero, léxico, calificador y enrutador son deterministas (gratis). Con
`gpt-4o-mini`, 100 conversaciones completas cuestan típicamente **menos de
1 USD**. Si la clave falla o se agota, el sistema degrada al simulador
automáticamente **sin romper la operación**.

---

## 6. Puesta en marcha 🚀

**Forma fácil** — usa el lanzador (activa el `.venv` solos):

```bash
# Linux / macOS                    # Windows
bash ejecutar.sh                   doble clic en ejecutar.bat
bash ejecutar.sh --web             ejecutar.bat --web
```

**Forma manual** (con el `.venv` activado):

| Modo | Comando | Resultado |
|---|---|---|
| Escritorio | `python main.py` | Ventana nativa con las 2 micro-apps (chat + bandeja del operador) |
| Navegador | `python main.py --web` | Abre `http://localhost:8550` — comparte la URL en tu LAN para que el operador entre desde otro equipo |
| Puerto custom | `python main.py --web --port=9000` | Útil si el 8550 está ocupado |

**Primer uso en 60 segundos:**

1. En la micro-app **Chat del cliente** escribe: *«Quiero los audifonos TWS
   Pro, cuanto vale? los necesito hoy mismo, mi numero es 04141234567»*.
2. Observa el panel de telemetría: idioma detectado, argot reconocido, score
   (subirá a ~88 → CALIENTE) y la traza de agentes `Portero → Léxico → …`.
3. La IA propondrá agenda: responde *«dale, la primera»* → cita agendada y
   **venta registrada en canal IA** sin intervención humana.
4. Abre la pestaña **Bandeja del operador** para ver la cita, la venta y las
   conversaciones que el enjambre derivó a humano.

---

## 7. Ejecutable de Windows — un solo .exe sin instalar Python 🪟 (v3.0)

Si vas a usar el sistema en una máquina donde no quieres instalar Python
(p. ej. la PC del mostrador), compila un ejecutable:

1. En la máquina donde tienes el proyecto (con Python instalado), doble clic a
   **`compilar_windows.bat`** (Linux/Mac: `./compilar_linux.sh`).
2. El script instala las dependencias en un `.venv` y compila con `flet pack`
   (PyInstaller). La primera vez tarda 5–15 minutos y descarga una sola vez el
   cliente de escritorio de Flet.
3. Al terminar: **`dist\AtencionDgtal.exe`** — un único archivo.

**Cómo se usa el ejecutable:**

- Cópialo a cualquier Windows y haz doble clic: abre la ventana de la app.
  No requiere Python ni instalación: no escribe nada en el registro.
- Al lado del `.exe` se crean solas las carpetas `data\` (base de datos) y
  `respaldos\`. Para la API key: crea un archivo de texto llamado `.env`
  junto al `.exe` (ver nota de abajo).
- Modo navegador (compartir en la red local): `AtencionDgtal.exe --web`.
- El ejecutable ya incluye el sistema de respaldos: pestaña ⚙️ igual que
  siempre, y los respaldos quedan en `respaldos\` junto al `.exe`.

> ⚠️ **Antivirus/Windows SmartScreen**: como el `.exe` no tiene firma digital,
> Windows puede mostrar "Windows protegió tu PC" → clic en *Más información →
> Ejecutar de todas formas*. Es normal en ejecutables caseros.

> 💡 **Nota para la API key en el ejecutable**: la primera vez que lo uses,
> crea junto al `.exe` un archivo llamado `.env` con
> `OPENAI_API_KEY=sk-…` (o entra a la pestaña ⚙️ y copia el .env desde tu
> instalación principal). Sin `.env`, el ejecutable funciona en modo demo.

---

## 8. Verificación y pruebas

Si quieres comprobar la instalación en cualquier momento (o después de un
cambio de máquina):

```bash
# Chequeo de salud completo (6 fases, sin tocar tus datos reales)
python verificar.py

# Suite de tests del enjambre, calificador, agenda e idioma (23 tests)
python -m unittest discover -s tests -v
```

`verificar.py` valida: versión de Python → dependencias → importación de los 4
niveles de la app → configuración `.env` → esquema SQLite → **un chat real
simulado** donde el enjambre califica, agenda y cierra una venta. Salida
esperada: `✅ INSTALACIÓN COMPLETA` y código de salida 0.

---

## 9. Copias de seguridad, actualización y desinstalación

| Acción | Cómo |
|---|---|
| **Respaldar datos** | Copia el archivo `data/atencion_dgtal.db` (contiene clientes, chats, citas y ventas) |
| **Respaldar configuración** | Pestaña ⚙️ de la app o `respaldar.bat` — genera un ZIP en `respaldos/` con base de datos, `.env` y catálogo (ver MANUAL.md, sección 6) |
| **Arrancar de cero** (borrar datos, mantener el sistema) | Borra `data/*.db` y reinicia la app |
| **Reinstalar dependencias** | Borra la carpeta `.venv` y ejecuta `instalar.sh` / `instalar.bat` de nuevo |
| **Desinstalar todo** | 1) Borra la carpeta del proyecto entera. 2) Nada más: todo vive dentro de esa carpeta (`.venv` incluido); no se escribe nada en el registro del sistema |
| **Cambiar de PC** | Copia el `.env` y `data/atencion_dgtal.db` al nuevo equipo sobre una instalación fresca |
| **Sincronizar vía GitHub** | Guía completa en **GITHUB.md**: publica con `publicar_github.sh/.bat`, sube cada cambio con `sincronizar.sh/.bat "mensaje"` y bájalo en otro PC con `actualizar.sh/.bat` |

---

## 10. Solución de problemas 🔩

| Síntoma | Causa probable | Solución |
|---|---|---|
| `python no se reconoce como comando` | Python no instalado o fuera del PATH | Reinstala Python marcando *«Add to PATH»* (Windows); en Linux: `sudo apt install python3 python3-venv python3-pip` |
| `No se pudo crear el entorno virtual` / `ensurepip is not available` | Falta el paquete `venv` (Ubuntu/Debian) | `sudo apt install python3-venv` y reintenta |
| PowerShell: «scripts deshabilitados en este sistema» | Política de ejecución restrictiva | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` o usa `cmd` con `activate.bat` |
| `pip install` falla con errores de red | Proxy corporativo o sin internet | Configura `pip install --proxy http://usuario:clave@proxy:puerto …`; el modo demo **no** necesita red después de instalar |
| `ModuleNotFoundError: No module named 'flet'` | El `.venv` no está activado | Ejecuta `bash ejecutar.sh` (lo activa solos) o reactiva con `source .venv/bin/activate` |
| La ventana de escritorio no abre (Linux) | Faltan librerías GTK del servidor gráfico | Usa el modo web: `python main.py --web` |
| `Address already in use` / puerto 8550 ocupado | Otra instancia o app usa el puerto | `python main.py --web --port=9000` (o cierra la otra instancia) |
| La app arranca pero responde «genérico» sin GPT | `.env` sin clave o clave inválida | Es la degradación esperada a MODO DEMO: revisa la variable `modo_llm` en la telemetría; corrige `OPENAI_API_KEY` y reinicia |
| `database is locked` | Dos instancias usando la misma BD | Cierra la otra instancia de la app |
| Error al descomprimir el ZIP | Descarga incompleta | Vuelve a descargar y verifica el tamaño del archivo |

Si nada funciona, ejecuta `python verificar.py` y comparte la salida: indica
exactamente en qué fase falló.

---

## 11. Checklist final ✅

- [ ] Python ≥ 3.10 instalado (`python3 --version`)
- [ ] ZIP descomprimido en una ruta sin acentos
- [ ] `bash instalar.sh` / `instalar.bat` ejecutado sin errores
- [ ] `verificar.py` muestra **INSTALACIÓN COMPLETA**
- [ ] `bash ejecutar.sh` abre la app con el chat del cliente
- [ ] (Opcional) `OPENAI_API_KEY` cargada en `.env` para GPT real

Con la casilla 5 marcada ya puedes correr la demo de 60 segundos del
`README.md`. ¡Listo para vender con el enjambre! 🐝
