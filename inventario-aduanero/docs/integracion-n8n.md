# Integración con n8n

Flujo: navegador → Express → Webhook → AI Agent + DeepSeek + Simple Memory + MySQL Tool de lectura → Respond to Webhook → Express → navegador.

La copia `n8n-webhook-inventario.json` está inactiva, no conserva ID del workflow original ni credenciales. Se mantienen los tipos/versiones de los nodos de IA que ya utiliza el original y su mensaje de sistema completo. No se ha importado, sobrescrito o activado automáticamente ningún workflow.

## Preparación manual

1. Abra n8n en http://127.0.0.1:5678. Cree un workflow nuevo e importe `docs/n8n-webhook-inventario.json`. No lo importe sobre su workflow original.
2. En DeepSeek Chat Model, seleccione su credencial DeepSeek existente. Se conserva `deepseek-v4-pro` tal como figura en el original; compruebe que su proveedor siga admitiéndolo.
3. En Consultar inventario aduanero, seleccione MySQL Aduana - Solo lectura, usando `aduana_wayner` y `aduana_lector`. No elija root ni una copia de prueba.
4. En Webhook, el método es POST y el path es `inventario-aduanero`. Respond debe ser **Using Respond to Webhook Node**.
5. La copia tiene **Header Auth**. Cree o seleccione una credencial Header Auth cuyo Name sea `X-Webhook-Secret` y Value sea un secreto privado. Ponga exactamente ese mismo valor en `N8N_WEBHOOK_SECRET` del `.env` del backend. No escriba el secreto en el workflow exportado.
6. AI Agent usa Prompt **Define below** y Text `={{ $('Webhook').item.json.body.message }}`.
7. Simple Memory usa Session ID **Define below** (`customKey`) y Key `={{ $('Webhook').item.json.body.sessionId }}`; ventana de 10 interacciones. El UUID no es compartido entre nuevas conversaciones.
8. Respond to Webhook usa JSON y Response Body `={{ { reply: $json.output } }}`. La salida debe ser un objeto, no texto JSON entrecomillado ni una propiedad `output` sin adaptar.
9. Guarde la copia. Para producción local, publique/active **esa copia** y copie su Production URL a `N8N_WEBHOOK_URL`.
10. Reinicie Express para cargar el entorno actualizado.

La autenticación también puede omitirse para una prueba exclusivamente local: cambie Authentication del Webhook a None y deje N8N_WEBHOOK_SECRET vacío. No mezcle Header Auth activo con un secreto vacío. La copia viene preparada para usar secreto.

## Prueba y producción

Si el chat muestra «Webhook de prueba no está escuchando», la solicitud recibió 404 antes de llegar al agente. Compruebe que el nodo exista y pulse Listen for test event para una prueba. Si eliminó el Webhook que agregó a mano, importe la copia preparada como workflow nuevo: ya contiene mensaje y memoria adaptados. El Chat Trigger del workflow original puede seguir funcionando independientemente. Para uso continuo, configure la Production URL de la copia y publíquela. Un 404 de producción también requiere verificar el método POST y el path exacto.

Test URL: `http://127.0.0.1:5678/webhook-test/inventario-aduanero`. Requiere pulsar Listen for test event en el editor; no queda siempre disponible. Copie temporalmente esa URL al `.env` y reinicie Express.

Production URL: `http://127.0.0.1:5678/webhook/inventario-aduanero`. Requiere la copia guardada y publicada/activa. En versiones recientes puede aparecer Publish en lugar de Active. Use la URL exacta que muestre su instancia si tiene un prefijo distinto. Luego restablezca esta URL en `.env` y reinicie Express.

## Contrato y prueba funcional

Petición de Express:

```json
{"message":"¿En qué bodegas hay computadoras?","sessionId":"01914e1b-57fc-4cc3-a8a7-cfdd3eb25748"}
```

Respuesta de n8n:

```json
{"reply":"Respuesta del agente basada en la herramienta MySQL."}
```

Puede probar desde Asistente IA o desde PowerShell contra Express, que valida entrada y agrega el secreto:

```powershell
$conversationId = [guid]::NewGuid().ToString()
$payload = @{message='¿En qué bodegas hay computadoras?'; sessionId=$conversationId} | ConvertTo-Json
Invoke-RestMethod -Uri http://127.0.0.1:3001/api/chat -Method Post -ContentType application/json -Body ([Text.Encoding]::UTF8.GetBytes($payload))
```

Pruebe luego «¿Y cuántas hay en bodega 1?» con el mismo sessionId. Una nueva conversación debe generar otro UUID. Compruebe en la ejecución de n8n que el agente llamó a MySQL y el stock provino de esa consulta.

El backend admite hasta 4000 caracteres, un UUID v4 y 12 preguntas por minuto/IP. Envía `X-Webhook-Secret` cuando está configurado. El timeout predeterminado es 60 segundos (configurable entre 1 y 120 segundos). Respuestas no JSON, sin reply válido, vacías, excesivamente largas o HTTP fallidos producen 503 controlado. Detener la espera en Express no garantiza cancelar una ejecución ya iniciada en n8n.

Las pruebas automáticas verifican el contrato con un servidor de prueba. No equivalen a comprobar DeepSeek, credenciales o memoria reales. La importación, selección de credenciales y activación de la copia deben realizarse en n8n antes de esa comprobación.

## Documentación oficial consultada

- [Webhook: modos de respuesta y URLs](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/)
- [Respond to Webhook](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.respondtowebhook/)
- [Autenticación de Webhook](https://docs.n8n.io/integrations/builtin/credentials/webhook/)
