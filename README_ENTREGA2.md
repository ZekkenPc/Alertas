# Sistema de alertas TI – Entrega 2 (API REST + app Flutter)

Alumno: Daniel Ivan Lucas Molina

Contenido:

```
backend/   API REST (Node.js + Express)
app/       Código actualizado de la app Flutter (lib/, pubspec.yaml, test/)
```

## 1. Qué incluye esta entrega

| Requisito                                   | Dónde está                                                               |
| ------------------------------------------- | ------------------------------------------------------------------------ |
| Consumo de una URL (API REST)               | `lib/services/api_client.dart`, `lib/config/api_config.dart`             |
| Práctica 3 (ConsultaWeb)                    | `lib/screens/consulta_screen.dart` → menú ⋮ → "Consulta de información"  |
| Recepción de incidentes en tiempo casi real | `home_shell.dart` consulta la API cada 15 s y avisa de incidentes nuevos |
| Almacenamiento estructurado (SQLite)        | `lib/services/local_db.dart` (caché con 4 tablas)                        |
| Funcionamiento sin conexión                 | `monitoring_repository.dart` usa el caché si la API falla                |
| Código seguro                               | `login_screen.dart`, `validators.dart`, `auth_service.dart`              |
| API REST                                    | `backend/`                                                               |

## 2. Levantar el backend

Requiere Node.js 18 o superior (https://nodejs.org).

```
cd backend
npm install
npm start
```

Verifica en el navegador: http://localhost:3000/api/info

Pruebas automáticas del backend: `npm test` (9 pruebas).

Variables opcionales: `PORT` (3000), `JWT_SECRET` (clave del token) y
`SIMULATOR_SECONDS` (45; con `0` se desactiva el simulador de alertas).

**Windows:** si pide permiso de Firewall para Node.js, acepta (red privada).

### Usuarios de prueba

| Usuario     | Contraseña   | Rol         |
| ----------- | ------------ | ----------- |
| coordinador | Coord#2026   | coordinador |
| tecnico1    | Tecnico#2026 | tecnico     |
| tecnico2    | Tecnico#2026 | tecnico     |

En el servidor solo se guardan hashes bcrypt, no contraseñas.

### Endpoints

| Método | Ruta                                                     | Acceso                                     |
| ------ | -------------------------------------------------------- | ------------------------------------------ |
| GET    | /api/health                                              | público                                    |
| GET    | /api/info                                                | público (práctica 3)                       |
| POST   | /api/auth/login                                          | público, limitado a 20 intentos por 15 min |
| GET    | /api/incidentes (filtros `severidad`, `estado`, `desde`) | token                                      |
| GET    | /api/incidentes/:id                                      | token                                      |
| POST   | /api/incidentes                                          | token, solo coordinador                    |
| GET    | /api/servidores                                          | token                                      |
| GET    | /api/resumen                                             | token                                      |

Prueba rápida con curl (en Git Bash):

```
curl http://localhost:3000/api/info
curl -X POST http://localhost:3000/api/auth/login -H "Content-Type: application/json" -d '{"usuario":"coordinador","clave":"Coord#2026"}'
```

El simulador agrega un incidente nuevo cada 45 s para ver la recepción en
tiempo casi real. También puedes crear uno con el token del coordinador:

```
curl -X POST http://localhost:3000/api/incidentes -H "Authorization: Bearer TU_TOKEN" -H "Content-Type: application/json" -d '{"titulo":"Prueba de alerta","servidor":"APP-WEB-01","severidad":"P1"}'
```

## 3. Actualizar la app Flutter

1. Copia `app/lib`, `app/pubspec.yaml` y `app/test` sobre tu proyecto
   (reemplaza). **No borres la carpeta `android/`**.
2. Opcional: borra `assets/data/` (el JSON local ya no se usa).
3. Edita `android/app/src/main/AndroidManifest.xml`:
   - Antes de la etiqueta `<application ...>` agrega el permiso de internet:
     ```xml
     <uses-permission android:name="android.permission.INTERNET"/>
     ```
   - Dentro de `<application ...>` agrega el atributo:
     ```xml
     android:usesCleartextTraffic="true"
     ```
     Esto permite HTTP sin cifrar y es **solo para desarrollo**. En producción
     se usa HTTPS y se quita.

4. En la carpeta del proyecto:
   ```
   flutter pub get
   flutter run
   ```
   Ejecútalo en el **emulador de Android** (sqflite y el almacenamiento seguro
   no funcionan en Chrome).

### URL del servidor

| Dónde corre la app                | URL                                                          |
| --------------------------------- | ------------------------------------------------------------ |
| Emulador Android                  | `http://10.0.2.2:3000` (valor por defecto)                   |
| Teléfono físico (misma red Wi-Fi) | `http://IP_DE_TU_PC:3000` (la imprime el backend al iniciar) |

Para cambiarla sin editar código:

```
flutter run --dart-define=API_URL=http://192.168.1.50:3000
```

o edita `lib/config/api_config.dart`.

### APK

```
flutter build apk --release --dart-define=API_URL=http://IP_DE_TU_PC:3000
```

## 4. Práctica 3: pruebas

Abre la app, inicia sesión y entra a ⋮ → "Consulta de información".

| Prueba                    | Pasos                                                           | Resultado esperado                                                   |
| ------------------------- | --------------------------------------------------------------- | -------------------------------------------------------------------- |
| 1. Con conexión           | Backend encendido, pulsa CONSULTAR                              | "Consultando..." y luego el JSON de `/api/info`                      |
| 2. Sin conexión           | Detén el backend (Ctrl+C) o activa modo avión y pulsa CONSULTAR | "No fue posible obtener la información."                             |
| 3. Modificación de la URL | Cambia `API_URL` (otro puerto o IP) y vuelve a ejecutar         | Con URL incorrecta aparece el error; con la correcta, la información |

Requisitos funcionales: RF01 título "Consulta de información", RF02 botón
CONSULTAR, RF03 petición HTTP GET, RF04 respuesta en pantalla,
RF05 "Consultando...", RF06 mensaje de error de conexión.

### Preguntas de análisis

1. **¿Qué es una URL?** La dirección que identifica un recurso en la red: protocolo, servidor, puerto y ruta (por ejemplo `http://10.0.2.2:3000/api/info`).
2. **¿Qué significa que sea preasignada?** Que está definida de antemano en la aplicación (en `api_config.dart`) y el usuario no la escribe.
3. **¿Qué protocolo usa?** HTTP mediante una petición GET (en producción, HTTPS).
4. **¿Qué formato tiene la información?** JSON.
5. **¿Qué función cumple JSON?** Es un formato de texto ligero para intercambiar datos estructurados entre servidor y app; la app lo convierte en objetos.
6. **¿Qué sucede si la URL no está disponible?** La petición falla o agota el tiempo; la app captura el error y muestra "No fue posible obtener la información." sin cerrarse.
7. **¿Por qué controlar los errores de conexión?** Para que la app no se cierre, informar al usuario con un mensaje claro, permitir reintentar y no exponer detalles técnicos.
8. **¿Diferencia entre URL y API?** La URL es la dirección de un recurso; la API es el conjunto de rutas y reglas (endpoints) que define qué se puede pedir y qué se recibe. Una API tiene muchas URLs.
9. **¿Ventajas de separar la URL de la lógica?** Se cambia de entorno (pruebas, producción) sin tocar el código, se facilita el mantenimiento y las pruebas, y se evita repetir la dirección en varias partes.
10. **¿Cómo usar esta técnica en una app real?** Igual que este proyecto: la app consulta una API de monitoreo para obtener incidentes y servidores; también sirve para clima, catálogos, pedidos, etc.

## 5. Almacenamiento estructurado (SQLite) en esta entrega

Base `alertas_ti.db` con las tablas `incidentes`, `logs_incidente`
(relación 1:N con borrado en cascada), `servidores` y `metadatos`.
Cada vez que la API responde, el caché se actualiza; si la API falla, la app
muestra el último caché con un aviso de "Sin conexión". Al cerrar sesión se
borra el caché.

Las tablas de usuarios, mensajes y reportes de cierre se agregarán en la
Evaluación 3, junto con el chat y el formulario de cierre.

## 6. Código seguro aplicado

- Contraseña oculta (`obscureText`) con botón para mostrar u ocultar.
- Validaciones: campos obligatorios, usuario que no sea solo espacios, caracteres permitidos, longitud máxima y contraseña de al menos 8 caracteres.
- Mensajes de error genéricos ("Usuario o contraseña incorrectos"), sin revelar cuál dato falló ni detalles técnicos.
- No se imprimen credenciales (no hay `print` ni `debugPrint` con datos sensibles).
- El token se guarda cifrado con `flutter_secure_storage` (Android Keystore).
- Al expirar o ser rechazado el token (401) se cierra la sesión.
- Servidor: contraseñas con bcrypt, token JWT con expiración (8 h), límite de intentos de login, cabeceras de seguridad (helmet), validación de entradas y errores sin detalles técnicos.
- La validación del cliente no basta: el servidor vuelve a validar todo y es quien autentica.

## 7. Limitaciones actuales

- El backend guarda los datos en memoria: al reiniciarlo vuelven los datos de ejemplo.
- Las alertas son simuladas (simulador del servidor); no hay un sistema de monitoreo real conectado.
- Usa consulta periódica (cada 15 s). WebSockets y notificaciones push quedan para la Evaluación 3.
- HTTP sin cifrar solo para desarrollo.
