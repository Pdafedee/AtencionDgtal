# 📘 Manual de usuario — Atención Dgtal v3.0

Guía paso a paso para **usar el sistema** en el día a día. Está escrita para
quien nunca ha trabajado con este tipo de herramientas: cada acción se explica
desde cero.

> 🔧 Si aún no tienes el sistema instalado, empieza por **[INSTALACION.md](INSTALACION.md)**.
> 👨‍💻 Si quieres entender cómo está construido (arquitectura, agentes, código), lee
> **[README.md](README.md)**.

---

## 1. Qué es Atención Dgtal en 60 segundos

Es un vendedor digital que atiende a tus clientes por chat:

1. **Responde al instante**, en español latino/caribeño o en portugués de Brasil.
2. Entiende el **argot real** ("vc tem o preço?", "dale", "zap", "xq").
3. **Califica** al cliente de 0 a 100 y decide: cerrar la venta, proponer una
   cita, o **pasarlo a una persona** solo cuando de verdad hace falta.
4. Todo queda guardado: conversaciones, citas y ventas.

**Las 3 pestañas de la app:**

| Pestaña | Para qué sirve | ¿Quién la usa? |
|---|---|---|
| 💬 **Chat del cliente** | Simular/simular el canal del cliente y ver la IA trabajando | Demostraciones y pruebas |
| 🎧 **Bandeja del operador** | Atender los casos que la IA derivó a una persona | El operador humano |
| ⚙️ **Ajustes y respaldo** | Respaldos de configuración y diagnóstico | Administrador |

**Cómo abrir la app:** doble clic a `ejecutar.bat` (Windows) o `./ejecutar.sh`
(Linux/Mac). Si usas el **ejecutable** (`AtencionDgtal.exe`), doble clic y listo.

---

## 2. Primeros pasos (primera vez)

1. Abre la app → verás la pestaña **Chat del cliente** con un "Cliente Demo ES"
   ya creado para que pruebes sin miedo.
2. Fíjate en el encabezado: el chip **🧠 IA** dice si estás en modo *demo*
   (simulador local, sin internet) o conectado a **GPT real**. El modo demo es
   100 % funcional para probar; solo no conversa con un LLM real.
3. Escribe tu primer mensaje de prueba (como si fueras un cliente):

   ```
   Quiero los audífonos TWS Pro, cuanto vale? los necesito hoy, mi numero es 04141234567 llamame
   ```

4. Observa:
   - la respuesta de la IA con **2 opciones de cita** (lead CALIENTE),
   - la **telemetría** debajo del chat: idioma, argot detectado, score 0-100,
     temperatura, jugada decidida y la traza del enjambre.

> 💡 **Prueba en portugués**: `vc tem o preco do fone? quero hoje, me manda no zap`
> → la IA detecta 🇧🇷 y responde en portugués.

---

## 3. Cerrar una venta (flujo completo de la IA)

Cuando un cliente está "caliente" (score ≥ 70), la IA propone la agenda:

1. La IA responde con **2 franjas**: *"¿Cuál te queda mejor?"*
2. El cliente responde p. ej. `dale, la primera`
3. Aparece **¡Trato cerrado!**: la cita queda confirmada y la venta registrada
   (canal IA). Ya aparece en la **Bandeja del operador** → panel derecho:
   "📅 Agenda interna" y "💰 Ventas registradas".

No hace falta que una persona toque nada: esa es la regla de oro del negocio —
**el humano solo entra cuando el enjambre decide derivar**.

---

## 4. Atender casos como operador humano (bandeja)

Cuando un cliente pide una persona (`quiero hablar con una persona`), la
conversación aparece en la **Bandeja del operador**:

1. Abre la pestaña **🎧 Bandeja del operador**.
2. En la columna izquierda haz clic en la conversación derivada.
3. Botones disponibles:
   - **🎧 Tomar conversación** — activa el modo humano: el chat deja de responder
     con IA para ese cliente.
   - **Responder** — escribe en el campo inferior y pulsa Enviar (el cliente ve
     tus mensajes en verde 🎧).
   - **💰 Registrar venta** — elige el producto y el monto; la venta queda
     registrada con canal HUMANO.
   - **🤖 Devolver a la IA** — el enjambre retoma la conversación donde iba.
4. Las **métricas** de arriba (conversaciones, leads calientes, derivadas,
   citas, ventas y monto) se actualizan solas.

> 💡 Si abres la pestaña Bandeja y no ves algo nuevo, haz clic otra vez sobre
> la pestaña: se refresca automáticamente al entrar y con cada actividad del chat.

---

## 5. Cambiar de rubro e industria (multirubro)

Arriba del chat está el selector **"Rubro activo"** con 3 industrias de demo:
E-commerce (TiendaExpress), Seguros (AseguraYa) y Telecom (ConectaMax). El
rubro aplica a las conversaciones **nuevas**.

**Personalizar el catálogo sin tocar código (v3.0):**

1. Copia `app/config.py` aparte como plantilla y crea el archivo
   **`data/rubros_personalizados.json`** con el mismo formato:

   ```json
   {
     "farmacia": {
       "etiqueta": "Farmacia · SaludYa",
       "negocio": "SaludYa",
       "contexto": "medicamentos con entrega el mismo día",
       "productos": [
         {"nombre": "Kit Gripe", "precio": 8.5, "beneficio": "entrega hoy",
          "claves": ["gripe", "kit", "medicina", "remedio"]}
       ]
     }
   }
   ```

2. Cierra y abre la app: el rubro aparece en el selector.
3. El sistema de respaldos guarda este archivo y lo restaura donde haga falta.

---

## 6. Respaldos: tu configuración a salvo (asistente v3.0)

### Desde la app (recomendado)

1. Pestaña **⚙️ Ajustes y respaldo**.
2. Marca qué incluir:
   - ☑ **Base de datos** — clientes, chats, citas y ventas.
   - ☑ **Configuración .env** — incluye tu API key (el ZIP es privado: guárdalo seguro).
   - ☑ **Catálogo de rubros** — tus personalizaciones.
3. **Crear respaldo ahora** → aparece en la lista de abajo con fecha y tamaño.
4. Copia el ZIP (`respaldos/respaldo_ADG_…zip`) a una memoria USB o a la nube.

### Restaurar un respaldo

1. Misma pestaña → lista **📦 Respaldos guardados** → **Restaurar**.
2. Lee la confirmación (la base actual se reemplaza; tu `.env` anterior se
   conserva como `.env.previo_al_respaldo`) → **Sí, restaurar**.
3. El catálogo de rubros restaurado se activa al reabrir la app.

### Desde la consola (sin abrir la app)

```bash
python asistente_respaldo.py     # o doble clic a respaldar.bat (Windows)
```

El asistente pregunta paso a paso: **1) Crear** (te pregunta qué guardar),
**2) Ver** los respaldos existentes, **3) Restaurar** (te deja elegir qué).
⚠️ Para restaurar la base de datos desde consola, cierra primero la app.

> 💡 **Buen hábito**: crea un respaldo cada semana y cada vez que cambies algo
> importante. Probar la restauración una vez te da paz mental para siempre.

---

## 7. Recetas del día a día

| Quiero… | Hago esto |
|---|---|
| Probar el sistema sin internet | Nada: sin API key funciona el modo demo |
| Conectar GPT real | Edita `.env` → `OPENAI_API_KEY=sk-…` y reabre la app |
| Compartir por navegador en mi red | `python main.py --web` → los demás entran a `http://TU-IP:8550` |
| Cambiar el puerto | `python main.py --web --port=9000` |
| Navegador viejo/sin WebGL | `python main.py --web --render=skwasm` |
| Borrar todos los datos y empezar de cero | Cierra la app y borra la carpeta `data/` |
| Ver la salud del sistema | `python verificar.py` |
| Saber qué versión tengo | Chip del encabezado o tarjeta "ℹ️ Esta instalación" |

---

## 8. Preguntas frecuentes (FAQ)

**¿La IA atiende sola siempre?**
No cuando no debe: si el cliente pide una persona, o el enjambre no logra
avanzar, deriva a la bandeja humana. Ese es el diseño: IA primero, humano
exactamente cuando aporta.

**¿Se pierden los chats si cierro la app?**
No. Todo vive en la base SQLite (`data/atencion_dgtal.db`), que sobrevive a
apagones y reinicios. Igual haz respaldos (sección 6).

**¿Dónde está mi API key y quién la ve?**
Solo en tu archivo `.env`, que **nunca** se sube a GitHub (lo protege
`.gitignore`) y solo viaja en los respaldos si tú lo marcas.

**¿Funciona con varios operadores a la vez?**
La app web acepta varias sesiones de navegador; la bandeja se refresca con cada
actividad. Para un equipo grande, usa el modo `--web` en un equipo servidor.

**El cliente escribió en portugués y la IA respondió en español, ¿por qué?**
La detección es por mensaje con heurísticas; si la frase es muy corta y sin
diacríticos (p. ej. "oi"), puede fallar. El cliente escribe otra frase normal y
se corrige.

**¿Cómo actualizo a una versión nueva sin perder datos?**
Crea un respaldo (sección 6) → instala la versión nueva en otra carpeta →
restaura el respaldo ahí. También puedes sincronizar por GitHub (GITHUB.md).

---

## 9. Problemas y soluciones rápidas

| Síntoma | Causa probable | Solución |
|---|---|---|
| La ventana se abre en blanco/gris | Navegador antiguo (modo web) o GPU bloqueada | `python main.py --web --render=skwasm`; actualiza Chrome/Edge/Firefox |
| "IA: Modo demo · simulador local" | Falta la API key | Escribe `OPENAI_API_KEY=sk-…` en `.env` y reabre |
| La app no abre tras instalar | Dependencias incompletas | Ejecuta `instalar.bat` de nuevo o `pip install -r requirements.txt` |
| No puedo restaurar desde consola | La app está abierta (base bloqueada en Windows) | Cierra la app y repite |
| El asistente de respaldo no ve mis ZIP | Carpeta personalizada | Define `ADG_CARPETA_RESPALDOS` en `.env` con la ruta correcta |
| Quiero reportar un bug | Necesitamos tu diagnóstico | Pestaña ⚙️ → tarjeta "Esta instalación" → copia y envía |

¿Nada de esto funciona? → `python verificar.py` te dice exactamente qué capa
falla; pega su salida al pedir ayuda.

---

*Atención Dgtal v3.0 · manual de usuario · dividir para conquistar, también al explicarlo*
