import { env } from '../config/env.js';
import { HttpError } from '../utils/HttpError.js';
export async function ask(payload) {
  if(!env.webhook) throw new HttpError(503,'Configure el Webhook de n8n en el backend.');
  try {
    const response=await fetch(env.webhook,{method:'POST',headers:{'Content-Type':'application/json',...(env.secret?{'X-Webhook-Secret':env.secret}:{})},body:JSON.stringify(payload),signal:AbortSignal.timeout(env.timeout)});
    if(response.status===404) {
      const testUrl=new URL(env.webhook).pathname.includes('/webhook-test/');
      throw new HttpError(503,testUrl
        ? 'El Webhook de prueba de n8n no está escuchando. Pulse «Listen for test event» en el nodo Webhook y vuelva a enviar. Para uso continuo, publique la copia del workflow y configure su Production URL en backend/.env.'
        : 'n8n no tiene registrado este Webhook. Compruebe la Production URL, el método POST y que la copia del workflow esté publicada o activa.');
    }
    if(response.status===401||response.status===403) throw new HttpError(503,'n8n rechazó la autenticación. Compruebe que Header Auth use X-Webhook-Secret y coincida con N8N_WEBHOOK_SECRET del backend.');
    if(!response.ok) throw new HttpError(503,'El workflow de n8n falló. Revise su última ejecución: entrada del agente, clave de memoria y credenciales.');
    const data=await response.json().catch(()=>null);
    if(!data || typeof data.reply!=='string'||!data.reply.trim()||data.reply.length>100000) throw new HttpError(503,'n8n respondió sin un reply válido. Configure Respond to Webhook para devolver el objeto JSON { reply: $json.output }.');
    return {reply:data.reply};
  } catch(error) {
    if(error instanceof HttpError) throw error;
    if(error.name==='TimeoutError'||error.name==='AbortError') throw new HttpError(503,'El agente de n8n tardó demasiado en responder. Revise la ejecución en n8n antes de reenviar la pregunta.');
    throw new HttpError(503,'No se pudo conectar con n8n. Compruebe que esté iniciado y que N8N_WEBHOOK_URL sea correcta.');
  }
}
