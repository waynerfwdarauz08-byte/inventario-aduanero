import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
const sql=fs.readFileSync(new URL('../../../Villalobos_Wayner_Aduana_Lab3.sql',import.meta.url),'utf8');
// Se analiza el archivo como texto; ninguna sentencia del adjunto se ejecuta.
const source=sql.replace(/--[^\r\n]*/g,'');const tables={};
for(const match of source.matchAll(/INSERT INTO\s+(\w+)\s*\(([^)]+)\)\s*VALUES\s*((?:'(?:[^']|'')*'|[^;'])+);/gi)){
 const columns=match[2].split(',').map(s=>s.trim());tables[match[1]]||=[];
 for(const row of match[3].matchAll(/\(([^()]*)\)/g)){
  const values=Array.from(row[1].matchAll(/'((?:[^']|'')*)'|(-?\d+(?:\.\d+)?)|\b(NULL)\b/g),m=>m[1]!==undefined?m[1].replaceAll("''", "'"):m[3]?null:Number(m[2]));
  assert.equal(values.length,columns.length);tables[match[1]].push(Object.fromEntries(columns.map((c,i)=>[c,values[i]])));
 }
}
test('el SQL confirma cantidades de tablas y registros',()=>{
 assert.equal([...sql.matchAll(/CREATE TABLE /g)].length,13);
 for(const [t,n] of Object.entries({declaracion:15,detalle_declaracion:18,contenedor:18,inventario:20,movimiento:23,inspeccion:15}))assert.equal(tables[t].length,n,t);
});
test('referencia: importaciones, retenidos, inspecciones y stock por bodega',()=>{
 assert.equal(tables.declaracion.filter(d=>d.regimen==='Importacion'&&d.fecha>='2026-10-01'&&d.fecha<'2026-11-01').length,10);
 assert.equal(tables.inventario.filter(i=>i.estado==='Retenido'&&i.cantidad>0).length,9);
 assert.equal(tables.inspeccion.filter(i=>i.resultado==='Con observaciones').length,8);
 const pcs=tables.inventario.filter(i=>i.id_producto===1);assert.equal(pcs.reduce((s,i)=>s+i.cantidad,0),100);
 assert.equal(pcs.find(i=>i.id_bodega===2).cantidad,80);assert.equal(pcs.find(i=>i.id_bodega===1).cantidad,20);
});
test('referencia: totales por país y empresa sin multiplicación por contenedores',()=>{
 const declarations=tables.declaracion;
 const sum=ds=>tables.detalle_declaracion.filter(dd=>ds.some(d=>d.id_declaracion===dd.id_declaracion)).reduce((s,dd)=>s+dd.valor_declarado,0);
 const china=declarations.filter(d=>d.id_pais_origen===1);assert.equal(sum(china),167500);
 assert.equal(tables.contenedor.filter(c=>china.some(d=>d.id_declaracion===c.id_declaracion&&d.regimen!=='Exportacion')).length,5);
 assert.equal(sum(declarations.filter(d=>d.id_pais_origen===10)),85800);
 const tech=declarations.filter(d=>d.id_importador===2&&d.regimen==='Importacion');assert.equal(tech.length,2);assert.equal(sum(tech),163000);
});
test('workflow adaptado inactivo, sin credenciales y con contexto explícito',()=>{
 const w=JSON.parse(fs.readFileSync(new URL('../../docs/n8n-webhook-inventario.json',import.meta.url),'utf8'));
 assert.equal(w.active,false);assert.ok(w.nodes.every(n=>!n.credentials));
 assert.match(w.nodes.find(n=>n.name==='AI Agent').parameters.text,/body.message/);
 assert.match(w.nodes.find(n=>n.name==='Simple Memory').parameters.sessionKey,/body.sessionId/);
 assert.equal(w.nodes.find(n=>n.name==='Webhook').parameters.authentication,'headerAuth');
});
