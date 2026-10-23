import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const original=JSON.parse(fs.readFileSync(path.join(root,'..','Agente IA - Inventario Aduanero.json'),'utf8'));
const nodes=original.nodes.filter(n=>!n.type.endsWith('.chatTrigger')).map(n=>{const copy=structuredClone(n);delete copy.credentials;return copy;});
const agent=nodes.find(n=>n.name==='AI Agent');agent.parameters.promptType='define';agent.parameters.text="={{ $('Webhook').item.json.body.message }}";
const memory=nodes.find(n=>n.name==='Simple Memory');memory.parameters={sessionIdType:'customKey',sessionKey:"={{ $('Webhook').item.json.body.sessionId }}",contextWindowLength:10};
nodes.unshift({parameters:{httpMethod:'POST',path:'inventario-aduanero',authentication:'headerAuth',responseMode:'responseNode',options:{}},type:'n8n-nodes-base.webhook',typeVersion:2.1,position:[-40,0],id:crypto.randomUUID(),name:'Webhook',webhookId:crypto.randomUUID()});
nodes.push({parameters:{respondWith:'json',responseBody:'={{ { reply: $json.output } }}',options:{}},type:'n8n-nodes-base.respondToWebhook',typeVersion:1.4,position:[600,0],id:crypto.randomUUID(),name:'Responder al backend'});
const connections=structuredClone(original.connections);delete connections['When chat message received'];connections.Webhook={main:[[{node:'AI Agent',type:'main',index:0}]]};connections['AI Agent']={main:[[{node:'Responder al backend',type:'main',index:0}]]};
fs.mkdirSync(path.join(root,'docs'),{recursive:true});
fs.writeFileSync(path.join(root,'docs','n8n-webhook-inventario.json'),JSON.stringify({name:'Inventario Aduanero - Webhook (copia)',nodes,connections,active:false,settings:{executionOrder:'v1'},pinData:{}},null,2)+'\n');
for(const name of ['dashboard','inventario','declaraciones','contenedores','bodegas','inspecciones','movimientos']){
  fs.writeFileSync(path.join(root,'frontend','src','services',name+'Service.js'),`import {request} from './apiClient.js';\nexport const get${name[0].toUpperCase()+name.slice(1)}=(path,options)=>request(path,options);\n`);
}
for(const dir of ['frontend/public','frontend/src/assets','frontend/src/utils'])fs.mkdirSync(path.join(root,dir),{recursive:true});
console.log('Copia inactiva generada; originales preservados.');
