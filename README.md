# Sistema de Inventario Aduanero · Laboratorio 3

Proyecto académico de Wayner Villalobos Arauz. Aplicación local de consulta con React + Vite, Node.js + Express, MySQL y un asistente conectado a n8n.

## Inicio rápido

Requiere Node.js 22.12+ o 24 LTS, MySQL iniciado y la base `aduana_wayner` existente, con un usuario de solo lectura.

```powershell
cd inventario-aduanero
npm ci
Copy-Item backend/.env.example backend/.env
Copy-Item frontend/.env.example frontend/.env
```

Complete las credenciales privadas en `backend/.env`. No sobrescriba un `.env` ya configurado. Luego, desde la raíz del repositorio o desde `inventario-aduanero`:

```powershell
npm run dev
```

Abra http://127.0.0.1:5173. La API usa el puerto 3001; n8n se administra por separado, habitualmente en el puerto 5678.

## Contenido

- [Aplicación e instrucciones completas](inventario-aduanero/README.md).
- [Integración del asistente con n8n](inventario-aduanero/docs/integracion-n8n.md).
- [Arquitectura y cálculos](inventario-aduanero/docs/arquitectura.md).
- [Registro de comprobaciones y pendientes](inventario-aduanero/docs/validacion.md).
- `Villalobos_Wayner_Aduana_Lab3.sql`: esquema y datos educativos originales de referencia.
- `Agente IA - Inventario Aduanero.json`: workflow original exportado, con referencias a credenciales de n8n, sin contraseñas ni API keys incrustadas. Deben seleccionarse credenciales propias al importar.
- Investigación académica y diagrama de relaciones del laboratorio.

**La base ya existe: no vuelva a ejecutar el script SQL para iniciar la página.** No se incluyen contraseñas, archivos `.env`, dependencias instaladas, builds ni evidencias que puedan mostrar credenciales. La aplicación es exclusivamente local, sin autenticación ni operaciones de escritura.

## Comprobaciones

Desde `inventario-aduanero`:

```powershell
npm test
npm run build
node scripts/verify-live.mjs
```

El último comando requiere acceso a la base real. Las pruebas de referencia leen el SQL como texto; nunca lo ejecutan ni modifican registros. La copia del workflow Webhook se entrega inactiva para configurarla en n8n.
