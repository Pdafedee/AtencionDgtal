# 🐙 Publicar Atención Dgtal en GitHub y sincronizarlo

Guía paso a paso, pensada para quien nunca usó Git. Al terminar tendrás:

1. Tu proyecto guardado en **tu cuenta de GitHub** (con historial de versiones).
2. Una rutina de **2 comandos** para subir cambios (`sincronizar`) y bajarlos
   (`actualizar`) desde cualquier computadora, o para trabajar en equipo.

---

## 1. Requisitos previos

| Necesitas | Dónde conseguirlo | Cómo comprobar |
|---|---|---|
| Cuenta en GitHub (gratis) | https://github.com/signup | Entras en github.com con tu usuario |
| Git instalado | https://git-scm.com/downloads | En una terminal: `git --version` |

> 💡 **Windows**: al instalar Git deja todas las opciones por defecto; incluye
> *Git Credential Manager*, que recuerda tu token para no pedirlo cada vez.
> En macOS y Linux puedes instalar Git con `xcode-select --install` o
> `sudo apt install git`.

Abre una terminal **dentro de la carpeta del proyecto** (`AtencionDgtal/`) y
trabaja desde ahí: todos los comandos de esta guía asumen que estás dentro.

---

## 2. Antes de empezar: tu configuración privada está protegida

El proyecto incluye un archivo `.gitignore` que le dice a Git qué **no** debe
subir. Ya viene configurado para excluir:

| Se excluye | Por qué |
|---|---|
| `.env` | ⚠️ Contiene tu `OPENAI_API_KEY`: es tu secreto, no sube **nunca** |
| `data/` | Tu base de datos local con conversaciones (se crea sola al arrancar) |
| `.venv/` | Tu entorno virtual (se recrea con `instalar.sh` / `instalar.bat`) |
| `__pycache__/` | Cachés de Python, puro ruido |

Lo que **sí** sube es `.env.example`: la plantilla *sin* secretos, para que
quien clone el proyecto sepa qué configurar.

> ⚠️ **Regla de oro**: no borres ni vacíes el `.gitignore`, y no pongas tu API
> key en ningún archivo que no sea `.env`.

---

## 3. Paso 1 — Crear el repositorio vacío en GitHub

### Opción A · Desde la web (la más fácil)

1. Entra en **https://github.com/new** con tu sesión iniciada.
2. **Repository name**: `atencion-dgtal` (minúsculas, sin espacios).
3. Elige **Private** (recomendado: solo tú lo ves) o Public si lo quieres open source.
4. **Muy importante**: deja **desmarcadas** las casillas *Add a README file*,
   *Add .gitignore* y *Choose a license*. El repositorio debe crearse **vacío**
   para no chocar con el primer envío del proyecto.
5. Pulsa **Create repository**.
6. GitHub te mostrará una dirección como
   `https://github.com/TU-USUARIO/atencion-dgtal.git` — cópiala: es la que
   le pasarás al script del paso 2.

### Opción B · Con GitHub CLI (una sola orden)

Si instalaste la CLI oficial ([cli.github.com](https://cli.github.com)) y
hiciste `gh auth login`, basta:

```bash
gh repo create atencion-dgtal --private --source . --push
```

Esto crea el repositorio, lo conecta y publica todo de una vez — puedes saltar
directamente al apartado 6.

---

## 4. Paso 2 — Publicar el proyecto por primera vez

Los scripts del proyecto hacen todo el trabajo (inicializan Git, firman tus
cambios, guardan la primera versión y la suben):

```bash
# Linux / macOS
bash publicar_github.sh https://github.com/TU-USUARIO/atencion-dgtal.git

# Windows
publicar_github.bat https://github.com/TU-USUARIO/atencion-dgtal.git
```

*(Si no pasas la URL, el script te la pedirá por teclado. Si aún no existe el
repositorio en GitHub, créalo primero como en el apartado 3.)*

### Qué hace el script (6 pasos)

1. Comprueba que Git está instalado.
2. Pregunta tu **nombre y correo** (una sola vez por máquina: firma tus cambios).
3. Crea el repositorio local (rama `main`).
4. Guarda la primera versión del proyecto (commit).
5. Conecta tu carpeta con la URL de GitHub (llamada `origin`).
6. Sube todo con `git push -u origin main`.

### Equivalente manual (si prefieres los comandos)

```bash
git init -b main
git add -A
git commit -m "Primera version de Atencion Dgtal"
git remote add origin https://github.com/TU-USUARIO/atencion-dgtal.git
git push -u origin main
```

Al terminar, refresca la página del repositorio en el navegador: verás todo el
código. 🎉

---

## 5. Autenticación: tu token de acceso (PAT)

GitHub **ya no acepta tu contraseña** al subir código: usa un *Personal Access
Token* (PAT). Solo se configura la primera vez.

### Crear el token

1. GitHub → esquina superior derecha, tu foto → **Settings**.
2. Menú izquierdo, abajo del todo → **Developer settings**.
3. **Personal access tokens** → **Tokens (classic)** → **Generate new token (classic)**.
4. Rellena:
   - *Note*: `atencion-dgtal` (un recordatorio para ti).
   - *Expiration*: 90 días (o *No expiration* para no renovarlo).
   - *Select scopes*: marca **`repo`** (acceso completo a repositorios).
5. **Generate token** → copia el token (`ghp_…`). ⚠️ Se muestra **una sola vez**:
   guárdalo en un lugar seguro (un gestor de contraseñas).

### Usar el token

La próxima vez que un script haga `push`, Git preguntará:

```
Username for 'https://github.com': TU-USUARIO
Password for 'https://TU-USUARIO@github.com': ghp_xxxx   ← el token, NO tu contraseña
```

- **Windows/macOS**: el Credential Manager lo guarda; no volverá a preguntar.
- **Linux**: guárdalo en caché para no escribirlo cada vez:
  ```bash
  git config --global credential.helper store   # lo guarda en ~/.git-credentials
  ```

---

## 6. El flujo diario — subir tus cambios (sincronizar)

Cada vez que modifiques el código (una mejora, un fix, lo que sea):

```bash
# Linux / macOS
bash sincronizar.sh "mejora: el calificador ahora pondera urgencia"

# Windows
sincronizar.bat mejora del calificador
```

El script hace automáticamente:

1. `git add -A` — detecta todos los archivos nuevos/modificados (respetando `.gitignore`).
2. `git commit -m "…"` — guarda una **foto** del proyecto en el historial.
3. `git push` — la sube a GitHub.

Si no escribes mensaje, usa la fecha y hora actual. Si no hay cambios, te avisa
y no hace nada. **Ese es todo el ritual**: editar → sincronizar.

> 💡 **Mensajes de commit buenos**: cortos y concretos — "corrigo detección PT
> en frases cortas", "añado rubro farmacia". En 6 meses te dirán *qué* cambió y
> *por qué*.

### Ver el historial

```bash
git log --oneline        # lista de versiones: código + mensaje
git status               # qué hay modificado ahora mismo
```

---

## 7. Bajar cambios — en otra computadora o en equipo

### Máquina nueva (primera vez): `git clone`

```bash
git clone https://github.com/TU-USUARIO/atencion-dgtal.git
cd atencion-dgtal
cp .env.example .env        # Windows: copy .env.example .env
# …edita .env con tu API key…
bash instalar.sh            # Windows: doble clic instalar.bat
bash ejecutar.sh            # ¡funcionando!
```

El clone trae **todo el código y el historial**, pero no tus secretos (`.env`)
ni tu base de datos (`data/`) — por eso se recrean.

### Máquina ya clonada: `actualizar`

```bash
bash actualizar.sh          # Windows: actualizar.bat
```

Baja la última versión publicada y la combina con la tuya. Si tenías cambios
sin guardar, los protege automáticamente (los guarda en un *stash*), actualiza,
y los restaura al final. Nunca pierdes trabajo por actualizar.

---

## 8. Flujo recomendado con dos máquinas (o en equipo)

```
Laptop (casa)        GitHub (la nube)         PC (oficina)
─────────────        ────────────────         ────────────
 editar código
 sincronizar.sh  ───►  sube versión
                          │  ────────────►  actualizar.sh
                          │                 editar código
 actualizar.sh  ◄─────────│  ◄────────────  sincronizar.sh
 (trae lo nuevo)          ▼                 (sube lo suyo)
```

**Regla de oro**: `actualizar` al empezar a trabajar, `sincronizar` al terminar
cada cambio. Así dos personas (o dos máquinas) nunca chocan.

---

## 9. Opcional: marcar versiones (tags)

Cuando una versión sea estable, etiquétala para poder volver a ella:

```bash
git tag -a v2.1.0 -m "Primera version publicada en GitHub"
git push --tags
```

Y en GitHub aparecerá en la sección *Releases* del repositorio. Para ver qué
cambió entre dos versiones: `git log v2.0.0..v2.1.0 --oneline`.

---

## 10. Seguridad: si llegaras a subir tu `.env` por error

1. **Rota la clave YA**: entra en https://platform.openai.com/api-keys, borra la
   clave expuesta y crea una nueva. (Aunque borres el archivo después, queda en
   el historial de Git: lo que importa es anular la clave.)
2. Quita el archivo del seguimiento y súbelo corregido:
   ```bash
   git rm --cached .env
   bash sincronizar.sh "quito .env del repositorio"
   ```
3. Comprueba que `.gitignore` sigue conteniendo la línea `.env`.

---

## 11. Problemas comunes

| Mensaje que ves | Qué significa | Solución |
|---|---|---|
| `Authentication failed` | Token incorrecto, vencido o sin scope `repo` | Genera otro (apartado 5) y reintenta |
| `! [rejected] … fetch first` | Hay cambios en GitHub que tu máquina no tiene | `bash actualizar.sh` y vuelve a `sincronizar` |
| `Please tell me who you are` | Git no sabe tu nombre/correo | `git config --global user.name "…"` + `user.email "…"` |
| `fatal: repository … not found` | URL mal escrita o repo privado sin permisos | Revisa la URL; Private exige el token correcto |
| `failed to push some refs` tras crear el repo con README | El repo remoto no estaba vacío | `git pull origin main --allow-unrelated-histories` y repite `git push -u origin main` |
| Se abre un editor raro al hacer commit | Hiciste `git commit` sin `-m` | Escribe el mensaje, guarda y sal: `Ctrl+O`, `Enter`, `Ctrl+X` (nano) o `:wq` (vim) |
| `CONFLICT (content)` al actualizar | Tú y GitHub cambiaron las mismas líneas | Abre el archivo, busca `<<<<<<<`, elige qué versión queda, borra las marcas, luego `git add -A`, `git commit` y `sincronizar` |
| En Linux me pide el token cada vez | No hay credential helper | `git config --global credential.helper store` |

---

## 12. Chuleta de comandos

| Quiero… | Comando |
|---|---|
| Publicar el proyecto (1ª vez) | `bash publicar_github.sh <URL>` |
| Subir mis cambios | `bash sincronizar.sh "mensaje"` |
| Bajar los cambios | `bash actualizar.sh` |
| Ver qué he tocado | `git status` |
| Ver el historial | `git log --oneline` |
| Descargar en una máquina nueva | `git clone <URL>` |
| Marcar una versión estable | `git tag -a vX.Y.Z -m "…"` + `git push --tags` |
| Conectar a otro repositorio | `git remote set-url origin <URL_nueva>` |

---

*Atención Dgtal · guía de GitHub · sincronizar y colaborar sin perder nada*
