# Arquitectura y criterios

El frontend sigue la cadena solicitada: componentes reutilizables → páginas → rutas → App → main → index. React Router monta el layout persistente y las diez páginas. QueryPage comparte filtros, carga, error, vacío y paginación. El acceso desde una bodega navega a Inventario con su ID aplicado en la URL, donde se consultan sus lotes y productos.

El backend usa rutas para definir HTTP, controladores para validar y responder, servicios para coordinar reglas, y repositorios para SQL. La capa de lectura solo permite SELECT de consultas internas fijas, sin múltiples sentencias; el cliente no proporciona SQL. Las condiciones se parametrizan y las columnas de orden se eligen en una lista cerrada. Un pool independiente sirve las vistas; el agente usa su propia credencial MySQL en n8n.

## Cálculos

- Valor declarado: `SUM(detalle_declaracion.valor_declarado)`. No se multiplica por cantidad. En listados de declaraciones, los detalles se agrupan por declaración antes de la unión.
- Dashboard: cada indicador tiene una subconsulta propia; no une detalles, inspecciones y contenedores en una agregación que pudiera multiplicar valores.
- Retenidos: número de lotes donde estado de inventario es Retenido y cantidad > 0.
- Inspecciones con observaciones: resultado exactamente Con observaciones; tener texto en observaciones no equivale a ese resultado.
- Contenedores recibidos por país: conteo de contenedores unidos a su única declaración y país, excluyendo Exportacion.
- Stock: inventario.cantidad directamente, sin sumarle ni restarle movimientos. No se presenta una suma entre productos de unidades incompatibles.
- Inventario enlaza detalle por id_declaracion **y** id_producto. El estado de declaración no sustituye el del lote.
- Detalle: cada conjunto se consulta por separado; solo el general presenta el total de la declaración.
- Bodegas: capacidad nominal m³, número de lotes y productos distintos con cantidad positiva. No muestra ocupación.
- Movimientos: bodega principal es receptora en Entrada, de salida en Salida, origen en Traslado. Destino y lote de destino conservan NULL cuando no corresponden.
- Fechas: MySQL retorna DATE y DATETIME como texto. El formateador separa componentes y nunca convierte DATE a una zona horaria. Los límites de fechas usan >= desde y < hasta + 1 día.

## Límites de ejecución

Express escucha en 127.0.0.1, configura Helmet y CORS para un único origen, admite JSON hasta 16 KB y limita el chat por IP. El navegador renderiza Markdown sin HTML arbitrario ni `dangerouslySetInnerHTML`. HTTP se cancela al desmontar páginas. Los errores públicos no contienen trazas, credenciales o consultas internas.

La aplicación no crea usuarios ni verifica permisos mediante intentos de escritura. El administrador debe conservar la cuenta de solo lectura. En n8n, el prompt es una orientación; SELECT concedido por MySQL es la restricción efectiva. No hay credenciales incrustadas en el workflow adaptado.

No se añaden ORM, autenticación ficticia, migraciones, nuevas tablas ni mecanismos de sincronización de stock. La adaptación del agente conserva el mensaje de sistema, DeepSeek y MySQL Tool originales.
