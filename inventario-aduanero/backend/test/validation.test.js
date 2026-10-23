import test from 'node:test';
import assert from 'node:assert/strict';
import {query,id,chat} from '../src/validators/query.js';
import {buildList} from '../src/repositories/inventoryRepository.js';
import app from '../src/app.js';
import {env} from '../src/config/env.js';
import {ask} from '../src/services/chatService.js';
import {createServer} from 'node:http';
test('paginación y entradas no escalares se rechazan',()=>{
  for(const input of [{page:'0'},{pageSize:'101'},{page:'1e3'},{search:['uno']},{page:'1 OR 1=1'},{producto:'-1'},{otro:'1'}])assert.throws(()=>query(input,'inventario'),{status:400});
  assert.equal(query({},'inventario').pageSize,10);
});
test('fechas reales, rangos, estados y UUID por conversación',()=>{
  for(const q of [{desde:'2026-02-30'},{hasta:'2026-13-01'},{desde:'2026-11-01',hasta:'2026-10-01'},{estado:'Liberada'},{regimen:'cualquiera'}])assert.throws(()=>query(q,'inventario'),{status:400});
  assert.equal(query({desde:'2026-10-01',hasta:'2026-10-31'},'declaraciones').hasta,'2026-10-31');
  for(const v of ['0','-1','1;DROP','99999999999'])assert.throws(()=>id(v));
  assert.throws(()=>chat({message:'hola',sessionId:'compartida'}));
  assert.throws(()=>chat({message:'x'.repeat(4001),sessionId:crypto.randomUUID()}));
  assert.equal(chat({message:' hola ',sessionId:crypto.randomUUID()}).message,'hola');
});
test('filtros parametrizados, ordenamiento permitido y FK compuesta',()=>{
  const injection="x' OR 1=1 --";
  const built=buildList('inventario',query({search:injection,bodega:'2',disponibilidad:'con-stock'},'inventario'));
  assert.ok(!built.sql.includes(injection));assert.ok(built.values.includes('%'+injection+'%'));
  assert.match(built.sql,/dd.id_declaracion=i.id_declaracion AND dd.id_producto=i.id_producto/);
  assert.match(built.sql,/i.cantidad>0/);
  assert.throws(()=>buildList('inventario',query({sort:'password'},'inventario')),{status:400});
  assert.throws(()=>buildList('bodegas',query({desde:'2026-10-01'},'bodegas')),{status:400});
  const dec=buildList('declaraciones',query({},'declaraciones'));
  assert.match(dec.sql,/SUM\(valor_declarado\).*GROUP BY id_declaracion/);
  assert.ok(!dec.sql.includes('JOIN contenedor'));assert.ok(!dec.sql.includes('JOIN inspeccion'));
});
test('API responde con errores consistentes, sin trazas ni SQL',async()=>{
  const server=app.listen(0,'127.0.0.1');await new Promise(r=>server.once('listening',r));
  const base=`http://127.0.0.1:${server.address().port}/api`;
  try{
    for(const [path,status,options] of [['/declaraciones/0',400],['/inventario?pageSize=101',400],['/no-existe',404],['/chat',400,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({message:'hola',sessionId:'compartida'})}],['/chat',400,{method:'POST',headers:{'Content-Type':'application/json'},body:'{'}]]){
      const response=await fetch(base+path,options);const data=await response.json();assert.equal(response.status,status);assert.equal(data.success,false);assert.equal(typeof data.error,'string');assert.ok(!JSON.stringify(data).includes('stack'));
    }
    const oversized=await fetch(base+'/chat',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({message:'x'.repeat(17000),sessionId:crypto.randomUUID()})});assert.equal(oversized.status,413);assert.equal((await oversized.json()).success,false);
    const originalUser=env.user;env.user='';
    try{const unavailable=await fetch(base+'/health',{headers:{Origin:env.origin}});assert.equal(unavailable.status,503);assert.equal(unavailable.headers.get('access-control-allow-origin'),env.origin);assert.ok(!(await unavailable.text()).includes('SELECT'));}finally{env.user=originalUser;}
    let limited=false;
    for(let n=0;n<13;n++){const response=await fetch(base+'/chat',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});if(response.status===429){limited=true;assert.equal((await response.json()).success,false);break;}}
    assert.ok(limited,'El chat debe limitar peticiones antes de invocar n8n.');
  }finally{await new Promise(r=>server.close(r));}
});
test('chat: contrato, secreto, respuesta inválida, fallo y timeout',async()=>{
  const previous={webhook:env.webhook,secret:env.secret,timeout:env.timeout};let mode='ok';
  const server=createServer((req,res)=>{if(mode==='timeout')return;assert.equal(req.headers['x-webhook-secret'],'solo-prueba');let body='';req.on('data',c=>body+=c);req.on('end',()=>{assert.equal(JSON.parse(body).message,'hola');res.writeHead(mode==='error'?500:200,{'Content-Type':'application/json'});res.end(JSON.stringify(mode==='invalid'?{output:'incorrecto'}:{reply:'Respuesta verificada'}));});});
  server.listen(0,'127.0.0.1');await new Promise(r=>server.once('listening',r));
  env.webhook=`http://127.0.0.1:${server.address().port}`;env.secret='solo-prueba';env.timeout=1000;
  try{const payload={message:'hola',sessionId:crypto.randomUUID()};assert.equal((await ask(payload)).reply,'Respuesta verificada');for(const m of ['invalid','error','timeout']){mode=m;if(m==='timeout')env.timeout=30;await assert.rejects(()=>ask(payload),{status:503});}}
  finally{Object.assign(env,previous);server.closeAllConnections();await new Promise(r=>server.close(r));}
});
