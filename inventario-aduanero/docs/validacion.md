# Registro de validación

Fecha: 23 de octubre de 2026, Costa Rica.

## Actualización antes de subir a GitHub

- `npm test`: 10 pruebas aprobadas, incluida la distinción entre Webhook no registrado, autenticación rechazada y respuesta sin reply válido.
- `node scripts/verify-live.mjs`: ejecución aprobada contra `aduana_wayner`. Confirmadas las 13 tablas, indicadores, paginación de las seis vistas, filtros de stock, producto, empresa y fechas, detalle de declaración y agregaciones por país. No se modificaron registros. El error de autenticación descrito en el registro inicial quedó resuelto.
- Se añadió `npm run dev` para iniciar API y frontend juntos desde la raíz del workspace o desde `inventario-aduanero`.
- El chat real sigue pendiente de importar/configurar/publicar la copia del workflow Webhook. La revisión visual automatizada también permanece pendiente.

Los apartados siguientes conservan el registro de la entrega inicial. Para el estado actual de MySQL y las pruebas, prevalece esta actualización.

## Realizado

- Leídos el SQL completo, workflow original y las seis páginas de la investigación. Se distinguieron las explicaciones educativas del PDF de la solicitud de implementación. No se ejecutaron ejemplos de DDL, DML o permisos del documento.
- Node 24.13.0 y npm 11.6.2 identificados; instalación de dependencias completada, lockfile generado. npm reportó cero vulnerabilidades en la instalación.
- `npm run build`: compilación de producción de Vite correcta, sin importaciones ni rutas de módulos rotas. Bundle principal de aproximadamente 455 KB sin comprimir / 143 KB gzip.
- `npm test`: 9 pruebas aprobadas. Incluyen conteos del SQL, agregaciones de referencia, filtros parametrizados, listas de orden, FK compuesta, fechas, paginación, validación de sesión, errores HTTP y chat con secreto/timeout/respuestas inválidas.
- Backend iniciado en 127.0.0.1:3001; frontend servido en 127.0.0.1:5173 con HTTP 200.
- MySQL escucha en el puerto 3306. Se intentó conectar con las credenciales privadas configuradas: MySQL respondió **1045 / ER_ACCESS_DENIED_ERROR**. No se muestra el valor de las credenciales.
- n8n responde `200 {status:ok}` en `/healthz` en el puerto 5678. Una petición real al chat de Express devolvió **503 controlado**; no se confirmó ejecución del nuevo Webhook ni respuesta de DeepSeek.
- Se generó una copia importable inactiva de n8n, sin bloques de credenciales, con mensaje y clave de memoria tomados explícitamente del Webhook. El original se conserva.
- Se implementaron breakpoints 1150, 850 y 600 px, tablas con desplazamiento interno, etiquetas, foco visible, menú móvil con Escape, confinamiento y retorno de foco, y estados de carga/error/vacío/reintento.

## Referencias confirmadas leyendo el SQL, no consultando la base viva

13 tablas; 15 declaraciones; 18 detalles; 18 contenedores; 20 lotes; 23 movimientos; 15 inspecciones. Diez importaciones en octubre de 2026; nueve lotes retenidos con stock; cinco contenedores recibidos de China excluyendo exportaciones; Tecnologia Central USD 163000 y dos importaciones; ocho inspecciones con resultado Con observaciones; cien computadoras, ochenta en bodega 2 y veinte en bodega 1; valor declarado China USD 167500 y Corea del Sur USD 85800.

Estas cifras se usan en pruebas de referencia; **no están codificadas en los indicadores de la aplicación**. Los indicadores solo consultan MySQL. El SQL del dashboard suma líneas una vez y preagrega los detalles en declaraciones antes de unirlos con datos generales.

## Pendiente y cómo verificar

1. Corregir DB_PASSWORD de `aduana_lector` en `backend/.env`, comprobar la cuenta en Workbench contra el mismo servidor y reiniciar Express. Ejecutar `node scripts/verify-live.mjs`. Este comando valida tablas, indicadores, filtros de stock/fecha/empresa/producto, paginación en las seis vistas y detalle con secciones independientes. La ejecución intentada no pudo superar la autenticación; no se presenta como validación aprobada contra MySQL.
2. Importar la copia del workflow como nueva, seleccionar las tres credenciales y activar/publicar esa copia. Seguir `integracion-n8n.md`. Probar una pregunta y una continuación con la misma sesión, luego otra conversación. La salud de n8n no confirma el funcionamiento del agente.
3. Revisión visual en navegador a 1440×900, 768×1024 y 390×844; comprobar navegación, scroll de tablas, filtros, detalle y chat. La herramienta de navegador de esta sesión no tenía navegadores disponibles y rechazó crear una pestaña IAB. Por tanto **no se tomaron capturas ni se aprobó QA visual de escritorio/móvil**. La compilación no sustituye esta comprobación.

No se ejecutó el script de creación ni INSERT, UPDATE, DELETE, DROP, TRUNCATE, ALTER, GRANT o migraciones contra la base. No se modificó ni activó el workflow existente.
