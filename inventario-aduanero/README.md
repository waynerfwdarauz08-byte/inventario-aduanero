# Sistema de Inventario Aduanero

Aplicación académica local de consulta sobre la base **existente** `aduana_wayner`. React + Vite, Express, MySQL y chat mediante n8n. No contiene altas, cambios, eliminaciones ni migraciones. Los datos del laboratorio son educativos.

**No ejecute nuevamente el script SQL para usar la aplicación.** Los archivos originales del workspace se conservan. La aplicación nunca utiliza una copia de prueba ni carga los datos del SQL como sustituto de MySQL.

## Requisitos

- Node.js 22.12+ o 24 LTS y npm. Implementado con Node 24.13.0 / npm 11.6.2.
- MySQL 8.0.46 iniciado, base `aduana_wayner` ya poblada y usuario con únicamente SELECT. La investigación identifica `aduana_lector`; use su contraseña real, no la de root.
- n8n local para el asistente; DeepSeek y credencial MySQL de lectura configurados. Las consultas de la aplicación funcionan aunque n8n no esté disponible.
- Navegador moderno con `crypto.randomUUID` (localhost / 127.0.0.1).

## Instalar y configurar

Desde la carpeta del proyecto:

```powershell
cd C:\Users\FWD8D\OneDrive\Desktop\LAB3MYSQL\inventario-aduanero
npm ci
# Solo si los archivos no existen todavía:
Copy-Item backend/.env.example backend/.env
Copy-Item frontend/.env.example frontend/.env
```

No sobrescriba un `.env` ya configurado. Abra `backend/.env` en VS Code y complete:

```dotenv
PORT=3001
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=aduana_wayner
DB_USER=aduana_lector
DB_PASSWORD=SU_CONTRASEÑA_PRIVADA
FRONTEND_ORIGIN=http://127.0.0.1:5173
N8N_WEBHOOK_URL=http://127.0.0.1:5678/webhook/inventario-aduanero
N8N_WEBHOOK_SECRET=SU_SECRETO_PRIVADO
N8N_TIMEOUT_MS=60000
```

No copie los textos de ejemplo como contraseñas reales. `.env` está excluido de Git. No envíe contraseñas por el chat ni las coloque en archivos VITE. La plantilla no contiene credenciales. La base debe permanecer `aduana_wayner`.

En `frontend/.env`:

```dotenv
VITE_API_BASE_URL=http://127.0.0.1:3001/api
```

Si omite este archivo, el frontend usa esa misma URL local. No use `localhost` y `127.0.0.1` indistintamente: CORS exige que el origen coincida exactamente.

## Iniciar

Puede iniciar frontend y backend juntos con una sola terminal, tanto desde `LAB3MYSQL` como desde `inventario-aduanero`:

```powershell
npm run dev
```

Abra http://127.0.0.1:5173 cuando Vite indique que está listo. Ctrl+C detiene ambos servicios. n8n se administra por separado.

Si prefiere iniciarlos por separado, use lo siguiente.

Dos terminales, ambas en `inventario-aduanero`:

```powershell
# Terminal 1
npm run dev:backend
```

```powershell
# Terminal 2
npm run dev:frontend
```

Abra **http://127.0.0.1:5173/**. La API usa http://127.0.0.1:3001/api. Ambos servidores escuchan exclusivamente en loopback. Detenga cada servicio con Ctrl+C.

Para cambiar el frontend: `npm run dev:frontend -- --port 5174`; actualice `FRONTEND_ORIGIN` y reinicie el backend. Para cambiar la API: modifique `PORT` y `VITE_API_BASE_URL`, reinicie ambos. `DB_PORT` y la URL del Webhook son independientes. Si cambia `.env`, reinicie el proceso: Node watch no garantiza recargar archivos de entorno.

En otra terminal, si n8n está instalado mediante npm y no está iniciado:

```powershell
n8n start
```

Abra http://127.0.0.1:5678. Si su instalación usa Docker o un servicio, iníciela con su mecanismo habitual; no cree una segunda instancia. Puede cambiar su puerto con `N8N_PORT` antes de iniciar n8n y actualizar `N8N_WEBHOOK_URL` en Express.

## Conectar el asistente

Importe **docs/n8n-webhook-inventario.json como workflow nuevo**, seleccione sus credenciales DeepSeek, MySQL de lectura y Header Auth. Defina `X-Webhook-Secret` en Header Auth y use el mismo valor en el `.env` privado del backend. La copia está inactiva y no reemplaza ni activa el original. Publique/active únicamente la copia cuando esté configurada. Consulte [las instrucciones completas](docs/integracion-n8n.md).

Contrato: Express envía `{ "message": "pregunta", "sessionId": "UUID v4" }`; n8n devuelve `{ "reply": "respuesta" }`. El navegador nunca llama directamente a DeepSeek ni recibe el secreto de n8n. Cada conversación tiene un UUID propio; su historial se guarda en `sessionStorage` de la pestaña. Nueva conversación cambia el UUID y limpia la vista.

## Organización

`frontend/src/components → pages → routes/AppRoutes.jsx → App.jsx → main.jsx → index.html`.

Las páginas componen componentes reutilizables. Servicios encapsulan HTTP; hooks controlan carga, cancelación y reintento; utilidades formatean números y fechas; estilos centralizan el diseño y sus variantes responsive.

`backend/src/routes → controllers → services → repositories → MySQL`. SQL fijo y parametrizado en repositorios. El pool utiliza `mysql2/promise`, `dateStrings` y límites de conexión. El backend rechaza consultas que no sean SELECT en su función de lectura; la barrera efectiva del agente es el usuario MySQL con permisos SELECT.

Vea [arquitectura y reglas de cálculo](docs/arquitectura.md).

## API

Las respuestas tienen `{success:true,data,meta?}` o `{success:false,error}`. `meta` incluye `page`, `pageSize`, `total`, `totalPages`.

- `GET /api/health`: comprueba API y acceso a MySQL; 503 si la base no está disponible.
- `GET /api/dashboard`: indicadores, regímenes, contenedores recibidos por país y últimas declaraciones.
- `GET /api/inventario`: search, producto, bodega, pais, estado del lote, disponibilidad (`con-stock` / `sin-stock`), desde, hasta.
- `GET /api/declaraciones`: search, desde, hasta, regimen, estado aduanero, empresa (ID).
- `GET /api/declaraciones/:id`: general, productos, contenedores, inspecciones y lotes independientes.
- `GET /api/contenedores`: search, pais, regimen.
- `GET /api/bodegas`: search y capacidad nominal, lotes, productos distintos con stock.
- `GET /api/bodegas/:id/inventario`: mismos filtros del inventario, restringido a esa bodega; 404 si no existe.
- `GET /api/inspecciones`: search, resultado, funcionario, desde, hasta.
- `GET /api/movimientos`: search, tipo, producto, bodega principal, desde, hasta.
- `GET /api/catalogos`: opciones reales de productos, bodegas, países, empresas y funcionarios.
- `POST /api/chat`: valida UUID v4, mensaje de 1–4000 caracteres; 12 preguntas/minuto/IP. Timeout configurable, 503 ante fallo del agente.

Los listados aceptan `page` (1–100000), `pageSize` (1–100; predeterminado 10), `sort` y `direction=asc|desc`. Orden permitido: inventario `fecha|cantidad|producto`; declaraciones `fecha|numero|valor`; contenedores `numero|peso`; bodegas `nombre|capacidad`; inspecciones `fecha|resultado`; movimientos `fecha|tipo`. Los IDs son enteros positivos; las fechas usan YYYY-MM-DD y hasta incluye el día completo. Búsquedas de hasta 200 caracteres. Filtros incompatibles se rechazan con 400. Los filtros iniciales abarcan todos los períodos.

Ejemplo: http://127.0.0.1:3001/api/inventario?estado=Retenido&disponibilidad=con-stock&page=1&pageSize=10

Errores: 400 entrada inválida; 404 recurso inexistente; 413 petición mayor a 16 KB; 429 límite de chat; 500 error interno; 503 MySQL o n8n no disponible. No hay endpoint de SQL arbitrario.

## Verificar

```powershell
npm test
npm run build
node scripts/verify-live.mjs
```

Las pruebas automáticas cubren validación, fechas imposibles, SQL parametrizado, FK compuesta, preagregación, respuestas de error y el contrato del chat con un servidor HTTP de prueba explícito. Este servidor no contiene ni simula datos de inventario. Las pruebas de referencia **leen el SQL como texto** sin ejecutarlo. `verify-live.mjs` consulta exclusivamente la base real y contrasta filtros, paginación, detalle y resultados académicos; necesita credenciales válidas y fallará si el conjunto de datos real cambió.

Consulte [el registro de validación](docs/validacion.md) para distinguir comprobaciones realizadas de las pendientes.

## Errores comunes

- **MySQL 1045 / Access denied:** abra `backend/.env`, revise `DB_USER=aduana_lector` y su contraseña. Compruebe esa cuenta en Workbench contra el mismo host/puerto. No use la API key de DeepSeek ni cambie permisos desde la aplicación. Reinicie la API después de guardar.
- **API no conecta:** inicie backend, revise puerto y `VITE_API_BASE_URL`. Si aparece EADDRINUSE, use otro puerto o detenga la instancia que inició usted.
- **CORS:** abra exactamente http://127.0.0.1:5173; ajuste `FRONTEND_ORIGIN` si usa otra dirección.
- **Chat 503:** compruebe que n8n está iniciado, la copia tiene credenciales, Header Auth coincide y está activa. `/webhook-test/` solo funciona mientras n8n escucha una prueba; `/webhook/` requiere el workflow publicado/activo.
- **Sin registros:** limpie filtros. El laboratorio contiene principalmente septiembre y octubre de 2026.
- **Build bloqueado en un entorno aislado Windows:** ejecute desde la terminal normal de VS Code; esbuild necesita leer la ruta del checkout. No es necesario desactivar protecciones del equipo.

## Alcance y límites

Versión local sin autenticación ni operaciones de escritura, sin despliegue público. No calcula ocupación, valor monetario del stock ni suma cantidades de unidades distintas. La memoria Simple Memory de n8n es local y no es un almacén durable garantizado; el historial del navegador desaparece al cerrar su sesión de pestaña. Las respuestas de IA deben contrastarse con las vistas. No se cambian datos para probar.
