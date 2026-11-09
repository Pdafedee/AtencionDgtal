# Atención Dgtal v3.0 🤖

**Sistema de atención automatizada impulsado por IA** que responde al instante, entiende el
argot local (español latinoamericano/caribeño 🇻🇪🇨🇴🇲🇽 y portugués brasileño 🇧🇷), **califica al
cliente** y **agenda la venta o deriva al operador humano solo cuando el trato lo requiere**.

| Componente | Tecnología |
|---|---|
| Interfaz (micro apps) | **Flet 1.0** (Python → escritorio y web) |
| Inteligencia artificial | **OpenAI** `gpt-4o-mini` (con simulador local de respaldo) |
| Coordinación de agentes | **Teoría de enjambre** (bus de eventos + blackboard + consenso) |
| Diseño del sistema | **Divide y vencerás** → arquitectura por capas |
| Persistencia | **SQLite** local (clientes, conversaciones, mensajes, citas, ventas) |
| Lenguaje | **Python 3.10+** |

---

## 1. La regla de oro del negocio

```
Cliente escribe → la IA responde al instante → califica (score 0-100)
        │
        ├─ Lead CALIENTE + contacto ──→ la IA PROPONE AGENDA y CIERRA LA VENTA sola
        ├─ Lead tibio/frío ──────────→ el agente vendedor descubre y construye el trato
        └─ Cliente pide humano ──────→ BANDEJA DEL OPERADOR con resumen completo
                                        (el humano entra solo entonces)
```

- **El operador humano solo interviene cuando el enjambre lo decide** (petición explícita del
  cliente o agenda llena). Puede tomar la conversación, registrar la venta cerrada o devolver
  el caso a la IA.
- Cuando hay `OPENAI_API_KEY` configurada, el closer conversa con **GPT real**; si la clave
  falta o la llamada falla, el sistema **degrada automáticamente al simulador local** sin
  romper nada (modo demo, costo cero). Solo los agentes que hablan consumen tokens: portero,
  léxico, calificador y enrutador son deterministas, auditables y gratis.

---

## 2. Arquitectura por capas (divide y vencerás)

El problema grande ("atender, entender y vender solo") se dividió en 4 capas
independientes, cada una resoluble y testeable por separado:

```
┌────────────────────────────────────────────────────────────────────┐
│  CAPA 4 · MICRO APPS (Flet)          app/ui/                       │
│  ┌────────────────────────┐    ┌───────────────────────────────┐   │
│  │ 💬 Chat del cliente    │    │ 🎧 Bandeja del operador       │   │
│  │ + telemetría en vivo   │    │ + agenda interna + ventas     │   │
│  └───────────┬────────────┘    └──────────────┬────────────────┘   │
├──────────────┼────────────────────────────────┼────────────────────┤
│  CAPA 3 · ENJAMBRE DE AGENTES IA (swarm)          app/swarm/       │
│   MENSAJE_CLIENTE                                          │      │
│      → 🚪 Portero  (idioma ES/PT, saludo)                  ▼      │
│      → 📖 Léxico   (argot chat → texto estándar)      eventos     │
│      → 🌡️ Calificador (score 0-100, D&C)               en cadena  │
│      → 🎯 Enrutador (decide LA jugada del turno)                   │
│      → { 💼 Vendedor  |  📅 Agenda  |  🎧 Derivador }              │
│   (bus pub/sub + blackboard compartido + consenso por prioridad)   │
├────────────────────────────────────────────────────────────────────┤
│  CAPA 2 · SERVICIOS                              app/services/     │
│   argot ES/PT · detector de idioma · calificador escorado          │
│   agenda (franjas y capacidad) · enrutador estratégico · SQLite    │
├────────────────────────────────────────────────────────────────────┤
│  CAPA 1 · NÚCLEO                                   app/core/       │
│   modelos puros: Cliente · Conversación · Mensaje · Cita · Venta   │
│   enums de dominio · configuración multirubro                      │
└────────────────────────────────────────────────────────────────────┘
```

**Divide y vencerás aplicado en tres niveles concretos:**

1. **Arquitectónico** — 4 capas desacopladas: la UI no conoce la IA, la IA no conoce SQL.
2. **Motor de calificación** (`app/services/calificador.py`) — el problema "¿qué tan
   comprador es este cliente?" se divide en 4 subproblemas (interés 30 %, presupuesto 30 %,
   urgencia 20 %, contacto 20 %), cada uno se resuelve por separado y luego se **combina**
   en un score 0-100 → FRÍO < 40 ≤ TIBIO < 70 ≤ CALIENTE.
3. **Búsqueda de señales** (`buscar_senales`) — explora el historial de mensajes con
   recursión clásica: divide la lista a la mitad, resuelve cada mitad y suma los resultados.

---

## 3. Teoría de enjambre (swarm) para los agentes IA

Cada agente es una unidad autónoma que **se suscribe a los eventos que sabe resolver**
(`app/swarm/base.py`). No hay un jefe con un if-else gigante: al entrar un mensaje del
cliente, el orquestador (`app/swarm/enjambre.py`) publica `MENSAJE_CLIENTE` en el bus y el
enjambre se **auto-organiza en cadena**:

```
MENSAJE_CLIENTE ──→ Portero ──→ TEXTO_NORMALIZADO ──→ Léxico ──→ SENALES_LISTAS
                                                                        │
        ACCION_DECIDIDA ←── Enrutador ←── SCORE_ACTUALIZADO ←── Calificador
              │
              ├── RESPONDER_VENTA ──→ 💼 Vendedor   (pregunta/oferta/refuerza)
              ├── PEDIR_CONTACTO  ──→ 💼 Vendedor
              ├── PROPONER_AGENDA ──→ 📅 Agenda     (2 slots + confirmación)
              ├── CONFIRMAR_CITA  ──→ 📅 Agenda     (cita + venta canal IA)
              ├── DERIVAR_HUMANO  ──→ 🎧 Derivador  (bandeja del operador)
              └── DESPEDIR        ──→ 💼 Vendedor

Colaboración: todos los agentes LEEN Y ESCRIBEN un blackboard compartido
(idioma, argot, score, cita propuesta, fase…).
Convergencia: el enjambre termina cuando la cola de eventos se vacía;
el consenso elige la respuesta de MAYOR PRIORIDAD DE ROL
(Derivador 6 > Agenda 5 > Vendedor 3 > Portero 1). Tope de 12 rondas por
mensaje garantiza terminación acotada (anti-bucle).
```

### Los 7 micro-agentes

| Agente | Archivo | Evento que activa | Responsabilidad |
|---|---|---|---|
| 🚪 **Portero** | `agente_portero.py` | `MENSAJE_CLIENTE` | Detecta idioma (ES/PT) en cada mensaje y saluda en el primero |
| 📖 **Léxico** | `agente_lexico.py` | `TEXTO_NORMALIZADO` | Reescribe argot ("vc", "xq", "blz", "ta'…") y prepara el historial |
| 🌡️ **Calificador** | `agente_calificador.py` | `SENALES_LISTAS` | Score 0-100 por divide y vencerás + temperatura del lead |
| 🎯 **Enrutador** | `agente_enrutador.py` | `SCORE_ACTUALIZADO` | Decide LA jugada única del turno (determinista y auditable) |
| 💼 **Vendedor** | `agente_vendedor.py` | `ACCION_DECIDIDA` | Descubre, ofrece, refuerza y pide contacto (único que consume tokens) |
| 📅 **Agenda** | `agente_agenda.py` | `ACCION_DECIDIDA` | Propone franjas, confirma cita y registra la venta con canal IA |
| 🎧 **Derivador** | `agente_derivador.py` | `ACCION_DECIDIDA` | Escala a la bandeja humana con resumen listo |

---

## 4. Micro apps (Flet)

- **💬 Chat del cliente** — canal del cliente con **telemetría del enjambre en vivo**:
  idioma, argot detectado, score/100 con barra, temperatura, jugada decidida, agente que
  respondió, modo IA y traza `Portero → Léxico → Calificador → Enrutador → …`.
  Selector de **rubro activo** (multirubro demo: e-commerce, seguros, telecom).
- **🎧 Bandeja del operador** — solo lo que la IA escaló: tomar conversación, responder como
  humano, **registrar venta cerrada** o **devolver a la IA**. Panel lateral con la
  **agenda interna** (citas confirmadas por la IA) y las **ventas registradas** (canal IA/HUMANO),
  más métricas: conversaciones, leads calientes, derivadas, citas y monto vendido.
- **⚙️ Ajustes y respaldo** (v3.0) — asistente visual para el usuario nuevo: **crear respaldos**
  de la configuración marcando casillas, ver los guardados y **restaurarlos con confirmación**;
  tarjeta "Esta instalación" con los datos de diagnóstico (versión, modo IA, rutas, umbrales).
  También existe el asistente de consola: `python asistente_respaldo.py`.

> 📖 ¿Primer día con el sistema? La guía **[MANUAL.md](MANUAL.md)** explica el uso paso a paso
> (y [INSTALACION.md](INSTALACION.md) cubre la instalación y el ejecutable de Windows).

## 5. Argot y bilingüismo

- **Detección automática ES/PT por mensaje** (heurística léxica + diacríticos: ñ vs ã/õ/ç/â/ê).
- **Normalización de argot chat**: `vc → você`, `xq/pq → porque`, `blz → beleza`,
  `tá/ta → está`, `wsp/zap → whatsapp`, `hj → hoje`, `mñn → mañana`… (diccionarios en
  `app/services/argot.py`, fácilmente ampliables).
- El argot detectado se muestra en la telemetría (🗣️) y el closer lo imita con naturalidad.

---

## 6. Instalación y ejecución

> 📦 **Guía completa paso a paso** (exportación del ZIP, requisitos, instalación
> automática o manual, configuración, respaldos y solución de problemas):
> **[INSTALACION.md](INSTALACION.md)**. Resumen rápido:

```bash
# Opción A — instalador automático (crea venv, instala, configura y verifica)
bash instalar.sh                   # Linux/Mac   ·   en Windows: doble clic instalar.bat

# Opción B — manual
cd AtencionDgtal
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env               # (opcional) GPT real — sin esto funciona en modo demo
```

```bash
# Ejecutar
python main.py                     # app de escritorio (ventana nativa)
python main.py --web               # navegador en http://localhost:8550
python main.py --web --port=9000   # puerto personalizado
```

Chequeo de salud del sistema (opcional, valida módulos, BD y un chat completo):
`python verificar.py`.

Atajos: `./ejecutar.sh` (Linux/Mac) o doble clic a `ejecutar.bat` (Windows) activan el venv
(si falta, lo crean), y lanzan la app.

> 🐙 **¿GitHub?** Para subir el proyecto a tu cuenta y sincronizarlo entre máquinas hay un
> kit de 3 scripts (`publicar_github` · `sincronizar` · `actualizar`) y una guía completa:
> **[GITHUB.md](GITHUB.md)** — detalle en la sección 11.

### Guion de demostración (60 segundos)

1. Abre la app → pestaña **Chat del cliente**.
2. Escribe como cliente caliente:
   `Quiero los audífonos TWS Pro, cuanto vale? los necesito hoy, mi numero es 04141234567 llamame`
   → telemetría: score ≥ 70 🔥 CALIENTE → la IA propone **2 franjas de agenda**.
3. Responde `dale, la primera` → **¡Trato cerrado!** cita confirmada + **venta registrada
   (canal IA)**. Mira la pestaña **Bandeja del operador**: aparece en "Agenda interna" y "Ventas".
4. Nueva conversación y escribe `quiero hablar con una persona` → el enjambre **deriva**;
   en la bandeja: **Tomar conversación → responder → Registrar venta** (canal HUMANO) o **Devolver a la IA**.
5. Prueba PT: `vc tem o preco do fone? quero hoje, me manda no zap` → detección 🇧🇷 y respuesta en portugués.

## 7. Tests

```bash
python -m unittest discover -s tests -v
```

42 pruebas cubren: detección de idioma, normalización de argot, motor escorado (incluida la
búsqueda divide y vencerás contra su equivalente de fuerza bruta), agenda (domingos,
capacidad, parseo de elección), 6 escenarios de integración del enjambre (cierre automático,
derivación, cliente brasileño, toma por operador, devolución a la IA), la ruta GPT real con
degradación al simulador (SDK mockeado, sin red ni costo), el **sistema de respaldo y
restauración** (crear, listar, restaurar con repositorio vivo, ZIP corruptos) y la
consistencia de versión (archivo `VERSION` ≡ `app/config.py`).

## 8. Configuración

| Variable | Defecto | Descripción |
|---|---|---|
| `OPENAI_API_KEY` | *(vacía → demo)* | Clave de OpenAI para GPT real |
| `ADG_MODELO` | `gpt-4o-mini` | Modelo del closer |
| `ADG_UMBRAL_CALIENTE` | `70` | Score mínimo para lead caliente |
| `ADG_UMBRAL_TIBIO` | `40` | Score mínimo para lead tibio |
| `ADG_DB_PATH` | `data/atencion_dgtal.db` | Ruta de la base SQLite |

**Multirubro:** el catálogo demo vive en `app/config.py` (`RUBROS`). Añadir una industria
nueva = añadir un bloque con sus productos (nombre, precio, beneficio, claves de detección);
el enjambre completo funciona sin tocar otra línea.

## 9. Estructura del proyecto

```
AtencionDgtal/
├── main.py                      # Punto de entrada (escritorio / --web / --render)
├── requirements.txt             # flet, openai, python-dotenv
├── .env.example                 # plantilla de configuración
├── MANUAL.md                    # manual de usuario paso a paso
├── INSTALACION.md               # guía completa de instalación, exportación y ejecutable
├── instalar.sh / instalar.bat   # instalador automático (venv + deps + .env + verificación)
├── verificar.py                 # chequeo de salud en 6 fases (incluye chat de prueba)
├── asistente_respaldo.py        # asistente de respaldo por consola (v3.0)
├── respaldar.sh / respaldar.bat # lanzador del asistente de respaldo
├── compilar_windows.bat         # crea el ejecutable de Windows (flet pack + PyInstaller)
├── compilar_linux.sh            # crea el ejecutable de Linux/Mac
├── VERSION                      # versión actual (la muestra el chip del encabezado)
├── .gitignore                   # protege .env, data/, respaldos/ y cachés
├── GITHUB.md                    # guía: publicar en GitHub y sincronizar entre máquinas
├── publicar_github.sh / .bat    # 1ª publicación en GitHub (asistente en 6 pasos)
├── sincronizar.sh / .bat        # subir cambios diarios (add + commit + push)
├── actualizar.sh / .bat         # bajar cambios hechos en otra máquina (stash seguro)
├── ejecutar.sh / ejecutar.bat   # lanzadores con venv automático
├── app/
│   ├── config.py                # ConfigGlobal + catálogo multirubro
│   ├── core/                    # CAPA 1 · núcleo
│   │   ├── enums.py             #   dominio cerrado (idioma, estado, franja, eventos…)
│   │   └── models.py            #   Cliente, Conversación, Mensaje, Cita, Venta
│   ├── services/                # CAPA 2 · servicios
│   │   ├── argot.py             #   léxico ES/PT + bancos de señales
│   │   ├── idioma.py            #   detección, normalización, simplificación
│   │   ├── calificador.py       #   score 0-100 con divide y vencerás
│   │   ├── agenda.py            #   franjas, capacidad, parseo de elección
│   │   ├── enrutador.py         #   máquina de decisiones estratégica
│   │   ├── respaldo.py          #   sistema de respaldo/restauración de config (v3.0)
│   │   └── db.py                #   repositorio SQLite (thread-safe)
│   ├── swarm/                   # CAPA 3 · enjambre
│   │   ├── base.py              #   AgenteBase + Evento (teoría de enjambre)
│   │   ├── enjambre.py          #   orquestador: bus, blackboard, consenso
│   │   ├── llm.py               #   ClienteLLM híbrido (GPT ↔ simulador)
│   │   ├── ctx.py               #   contexto compartido de los agentes que hablan
│   │   └── agente_*.py          #   los 7 micro-agentes
│   └── ui/                      # CAPA 4 · micro apps Flet
│       ├── tema.py              #   paleta, chips de telemetría, burbujas
│       ├── micro_app_chat.py    #   💬 chat del cliente
│       ├── micro_app_bandeja.py #   🎧 bandeja del operador
│       ├── micro_app_ajustes.py #   ⚙️ ajustes y respaldo (v3.0)
│       └── shell.py             #   contenedor + encabezado + navegación
└── tests/                       # 42 pruebas unitarias y de integración
```

## 10. Cómo extender

- **Nuevo agente**: hereda de `AgenteBase`, declara `suscripciones`, implementa `manejar()`
  y regístralo en `Enjambre.__init__` — el resto del sistema no cambia.
- **Nueva micro app**: clase autocontenida con `self.control` (root Flet) y móntala en `shell.py`.
- **Nuevo canal real (WhatsApp/Instagram)**: reemplaza la micro app chat por un adaptador que
  llame a `enjambre.procesar_mensaje_cliente()` — la API ya está lista.
- **Persistencia en la nube**: sustituye `Repositorio` por otra implementación con la misma interfaz.

---

## 11. Publicar en GitHub y sincronizar

El proyecto trae su kit completo de control de versiones. El `.gitignore` ya
protege tus secretos (`.env`), tu base de datos (`data/`) y tu entorno virtual
(`.venv/`): al repositorio suben el código y las plantillas, nunca lo privado.

| Script | Cuándo usarlo | Qué hace |
|---|---|---|
| `publicar_github.sh` / `.bat` | **Una sola vez** | Inicia Git, firma tus commits, guarda la 1ª versión y sube todo a tu cuenta |
| `sincronizar.sh` / `.bat` | **Cada cambio** | `add + commit + push` con mensaje descriptivo; avisa si no hay nada o si GitHub va por delante |
| `actualizar.sh` / `.bat` | **Otra máquina / equipo** | Baja lo publicado y lo combina, protegiendo antes tu trabajo local (stash) |

```bash
# 1) Crea el repositorio vacío en https://github.com/new y copia su URL
bash publicar_github.sh https://github.com/TU-USUARIO/atencion-dgtal.git

# 2) Con cada mejora…
bash sincronizar.sh "añado rubro farmacia"

# 3) …y en cualquier otra computadora
bash actualizar.sh
```

La autenticación usa un **token personal (PAT)** de GitHub en lugar de la
contraseña — se crea una sola vez y los scripts te guían. La guía completa
**[GITHUB.md](GITHUB.md)** cubre en 12 apartados: crear el repositorio, el PAT,
el flujo diario, `git clone` en una máquina nueva, trabajo en equipo, tags de
versión, qué hacer si se sube un secreto y la chuleta de comandos.

---

## 12. Historial de versiones

### v3.0.0 — respaldos con asistente, ejecutable de Windows y web corregida

- **✚ Sistema de respaldo de configuración** (`app/services/respaldo.py`): un respaldo es un
  ZIP autocontenido con metadata, base de datos (copiada con el API de respaldo de SQLite,
  consistente aunque la app esté corriendo), `.env` y catálogo de rubros. Se guarda en
  `respaldos/` dentro del proyecto (configurable con `ADG_CARPETA_RESPALDOS`).
- **✚ Asistente doble para el usuario nuevo**: pestaña **⚙️ Ajustes y respaldo** en la app
  (casillas + lista de respaldos + restauración con confirmación + tarjeta de diagnóstico)
  y asistente de consola `asistente_respaldo.py` (`respaldar.sh` / `respaldar.bat`).
- **✚ Catálogo de rubros personalizable sin tocar código**: si existe
  `data/rubros_personalizados.json` se fusiona sobre `RUBROS`; el respaldo lo guarda y lo restaura.
- **🐛 CORREGIDO (crítico, web)**: la página web salía **gris** en Flet 1.1+ por dos causas
  (reproducidas y verificadas en navegador): (1) `page.window.width/height` se aplicaba en
  modo web y rompía el layout — ahora solo en escritorio; (2) un control con `expand` dentro
  de una `Row(wrap=True)` (espaciador del encabezado) invalidaba el árbol — Flutter no admite
  flex dentro de Wrap. Verificado end-to-end: chat con score CALIENTE, agenda, bandeja y
  diálogos funcionando en navegador.
- **🐛 CORREGIDO**: `RAIZ_PROYECTO` apuntaba un nivel arriba del proyecto (`parents[2]`), así
  que `data/` y `respaldos/` se creaban fuera de la carpeta. Ahora `parents[1]`.
- **✚ Modo web más flexible**: `python main.py --web --render=skwasm|canvaskit|auto`
  (Flet 1.x requiere navegador moderno con WebGL; documentado).
- **✚ Ejecutable de Windows**: `compilar_windows.bat` usa `flet pack` (PyInstaller) para
  generar `dist\AtencionDgtal.exe` — un solo archivo que corre sin instalar Python, con
  cliente de escritorio y modo web incluidos (receta probada: HTTP 200 en `--web`).
- **✚ Manual de usuario** `MANUAL.md`: uso paso a paso para el operador y el nuevo usuario.
- **✚ `Repositorio.cerrar()/reabrir()`** para reemplazar la base en caliente al restaurar.
- Suite crece de 34 → **42 tests**.

### v2.1.0 — kit de GitHub y sincronización

- **✚ Publicar en GitHub**: `publicar_github.sh` / `.bat` — asistente en 6 pasos
  (Git, identidad, repositorio local, primera versión, conexión `origin`, push)
  con mensajes claros ante token vencido o repositorio no vacío.
- **✚ Sincronizar diariamente**: `sincronizar.sh` / `.bat` — un comando hace
  `add + commit + push`; mensaje automático con fecha si no lo escribes, y
  diagnóstico ("ejecuta `actualizar` y reintenta") si el remoto va por delante.
- **✚ Actualizar entre máquinas**: `actualizar.sh` / `.bat` — `git pull` con
  protección automática de cambios sin guardar (stash) y guía de resolución de
  conflictos cuando chocan ediciones.
- **✚ `.gitignore` reforzado**: `.env` (API key), `data/`, `.venv/`, `__pycache__/`,
  IDEs y archivos de sistema nunca suben al repositorio; `.env.example` sí sube.
- **✚ Guía `GITHUB.md`**: de "nunca usé Git" a colaborar en equipo, con capturas
  de flujo y tabla de 8 problemas comunes.
- **✚ Test de consistencia de versión** (la suite crece 33 → **34 tests**):
  `VERSION` y `app/config.py` no pueden divergir.

### v2.0.0 — auditoría funcional completa

- **🐛 CORREGIDO (crítico)**: con `OPENAI_API_KEY` configurada, GPT real **nunca llegó a
  conversar**: `ClienteLLM` pedía `config.max_historial_llm`, atributo que no existía, y el
  `AttributeError` resultante se tragaba en silencio degradando al simulador desde el primer
  turno. Ahora el atributo existe (configurable con `ADG_MAX_HISTORIAL_LLM`, por defecto 8),
  `construir_contexto` respeta ese límite y una suite nueva (`tests/test_llm.py`, SDK mockeado:
  sin red, sin costo) blinda la ruta GPT real y la degradación.
- **✚ Diagnóstico**: `ClienteLLM.ultimo_error` registra por qué se degradó al simulador.
- **✚ Versión visible**: archivo `VERSION`, chip `v2.0.0` en el encabezado de la app y número
  de versión en `verificar.py`.
- **✅ Verificación completa de funcionalidades**: los 4 niveles (núcleo, servicios, enjambre,
  micro apps) se probaron de punta a punta: chat ES/PT con argot, calificación 0-100,
  agenda con capacidad, cierre automático canal IA, derivación, bandeja (tomar/responder/
  registrar venta/devolver a la IA), métricas y modo web.
- Suite crece de 23 → **33 tests**; instaladores y guía de instalación incluidos.

### v1.0.0 — versión inicial

Enjambre de 7 micro-agentes, calificación escorado 0-100 (divide y vencerás), argot ES/PT,
agenda interna con capacidad, bandeja del operador, IA híbrida GPT/simulador, multi-rubro
(e-commerce, seguros, telecom), micro apps Flet escritorio/web, 23 tests.

---

*Atención Dgtal · enjambre de agentes IA · divide y vencerás · micro apps · ES/PT*
