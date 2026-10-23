import test from 'node:test';
import assert from 'node:assert/strict';
import {createServer} from 'node:http';
import {env} from '../src/config/env.js';
import {ask} from '../src/services/chatService.js';

test('el chat distingue Webhook de prueba, producción, autenticación y contrato',async()=>{
 const before={webhook:env.webhook,secret:env.secret,timeout:env.timeout};let status=404,body={stacktrace:'INTERNAL_PRIVATE_TRACE'};
 const server=createServer((req,res)=>{req.resume();res.writeHead(status,{'Content-Type':'application/json'});res.end(JSON.stringify(body));});
 server.listen(0,'127.0.0.1');await new Promise(r=>server.once('listening',r));
 const base=`http://127.0.0.1:${server.address().port}`;env.secret='';env.timeout=1000;
 const payload={message:'consulta de prueba',sessionId:crypto.randomUUID()};
 const fails=async(pattern)=>assert.rejects(()=>ask(payload),error=>error.status===503&&pattern.test(error.message)&&!error.message.includes('INTERNAL_PRIVATE_TRACE'));
 try{
  env.webhook=base+'/webhook-test/test';await fails(/Listen for test event/);
  env.webhook=base+'/webhook/test';await fails(/Production URL/);
  for(const code of [401,403]){status=code;await fails(/X-Webhook-Secret/);}
  status=500;await fails(/última ejecución/);
  status=200;body={output:'Respuesta sin adaptar'};await fails(/Respond to Webhook/);
  body=null;await fails(/reply válido/);
  body={reply:'Respuesta válida'};assert.equal((await ask(payload)).reply,body.reply);
 }finally{Object.assign(env,before);server.closeAllConnections();await new Promise(r=>server.close(r));}
});
