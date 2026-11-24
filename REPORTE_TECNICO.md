# Prácticas 13 y 14: Automatización de pruebas y validación continua

**Alumno:** Daniel Ivan Lucas Molina
**Aplicación:** Sistema de alertas TI (Flutter + API REST Node.js)
**Repositorio:** [pegar URL de GitHub]

> Los campos entre [corchetes] se completan con los datos reales de TU ejecución
> (tiempos, números de run, capturas). No los inventes: el profesor los puede
> contrastar con la pestaña *Actions* del repositorio.

## 1. Componentes críticos seleccionados (Fase 1)

| Tipo | Componente | Archivos |
|---|---|---|
| Función crítica del móvil | Inicio de sesión y validación de entradas | `utils/validators.dart`, `login_screen.dart` |
| Servicio / endpoint | `POST /api/auth/login`, `GET /api/incidentes` y manejo de errores de red | `services/api_client.dart`, `backend/src/routes/*` |
| Persistencia | Caché SQLite de incidentes y servidores | `services/local_db.dart`, `monitoring_repository.dart` |

**Defectos / riesgos detectados que una prueba automatizada previene:**

1. `Severity.parse` convierte cualquier severidad desconocida en P3 (la más baja) sin avisar; una alerta crítica con un valor inesperado se mostraría como "Medio". Cubierto por `models_test.dart`.
2. `ServerStatusX.parse` interpreta cualquier estado desconocido como "Caído". Cubierto por `models_test.dart`.
3. `test/widget_test.dart` (plantilla del contador de Flutter) ya no corresponde a la app: referencia `MyApp` y un botón `+` que no existen, por lo que haría fallar el pipeline.
4. [Agregar aquí el defecto de tu práctica anterior, con su ID.]

## 2. Matriz de automatización

| ID | Tipo | Qué valida | Archivo | Estado |
|---|---|---|---|---|
| AUT-01 | Unitarias | Validación de usuario y contraseña: vacío, nulo, longitud, caracteres | `test/validators_test.dart` | [Aprobada] |
| AUT-02 | Unitarias | Parseo de `Incident`/`Server`: válido, nulos, campo faltante (TypeError), fecha inválida (FormatException), severidad fuera de rango | `test/unit/models_test.dart` | [Aprobada] |
| AUT-03 | Unitarias | `formatDateTime`, `countBySeverity`, `Severity.code/label` | `test/unit/format_and_summary_test.dart` | [Aprobada] |
| AUT-04 | Integración | App ↔ API: login (POST/JSON/200/401), token Bearer; backend: 201 al crear, 400 fuera de rango, 429 por intentos | `test/integration/api_client_test.dart`, `backend/test/api_extra.test.js` | [Aprobada] |
| AUT-05 | Integración | Servidor caído, error 500, respuesta no JSON, token expirado; fallback a caché | `test/integration/api_client_test.dart`, `monitoring_repository_test.dart` | [Aprobada] |
| AUT-06 | Persistencia | Guardar/leer/reemplazar/borrar el caché SQLite; orden de logs | `test/integration/local_db_test.dart` | [Aprobada] |
| AUT-07 | CI | Job `flutter`: `pub get`, `analyze`, `test --coverage` en cada push y PR | `.github/workflows/ci.yml` | [Aprobada] |
| AUT-08 | CI | Job `backend`: `npm ci`, `npm test` en cada push y PR | `.github/workflows/ci.yml` | [Aprobada] |

## 3. Resultados de la ejecución (Fase 5)

| Suite | Ejecutadas | Aprobadas | Fallidas | Tiempo |
|---|---|---|---|---|
| Backend (`npm test`) | 17 | 17 | 0 | ≈ 2 s (medido localmente) |
| Flutter (`flutter test`) | [n] | [n] | [n] | [tiempo del job] |
| **Pipeline completo** | [n] | [n] | [n] | [duración total en Actions] |

**Evidencia:** [captura del run en verde] · [URL del run] · [captura del segundo run tras el nuevo push].

### Errores encontrados y correcciones

| # | Error | Causa | Corrección |
|---|---|---|---|
| 1 | `widget_test.dart` fallaba en el CI | Prueba plantilla del contador, sin relación con la app | Eliminada |
| 2 | [error real de tu primer run] | [causa] | [cambio realizado, commit] |

## 4. Conclusión técnica (Fase 6)

[Redáctala con tus palabras, 1 o 2 párrafos. Ideas a desarrollar:]

- Antes, cada cambio exigía repetir a mano el login, la lista y el modo sin conexión; ahora el pipeline lo verifica en cada push y PR.
- Las pruebas de integración con `MockClient` y SQLite real detectan roturas entre la app, la API y el caché que las pruebas unitarias no ven.
- Las pruebas que documentan riesgos (severidad desconocida → P3) hacen visible una decisión de diseño; si alguien la cambia, la prueba avisa.
- Límites: las pruebas no cubren la interfaz completa ni la API real sobre el emulador; el backend en memoria no prueba una base de datos real.
