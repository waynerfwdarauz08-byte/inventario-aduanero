import assert from 'node:assert/strict';
import {read,pool} from '../backend/src/config/database.js';
import {dashboard,list,detail} from '../backend/src/repositories/inventoryRepository.js';
import {query} from '../backend/src/validators/query.js';
try {
 const info=await read('SELECT DATABASE() base, COUNT(*) tablas FROM information_schema.tables WHERE table_schema=DATABASE()');assert.equal(info[0].base,'aduana_wayner');assert.equal(info[0].tablas,13);
 const d=await dashboard();for(const [k,v] of Object.entries({declaraciones:15,contenedores:18,retenidos:9,inspecciones:15,con_observaciones:8}))assert.equal(d[k],v,k);
 assert.equal(d.paises.find(p=>p.nombre==='China').total,5);
 for(const name of ['inventario','declaraciones','contenedores','bodegas','inspecciones','movimientos']){const a=await list(name,query({pageSize:'2'},name));const b=await list(name,query({pageSize:'2',page:'2'},name));assert.equal(a.data.length,2);assert.equal(b.data.length,2);assert.notDeepEqual(a.data,b.data);console.log(`${name}: lectura y paginación OK (${a.meta.total})`);}
 const retained=await list('inventario',query({estado:'Retenido',disponibilidad:'con-stock'},'inventario'));assert.equal(retained.meta.total,9);
 const imports=await list('declaraciones',query({regimen:'Importacion',desde:'2026-10-01',hasta:'2026-10-31'},'declaraciones'));assert.equal(imports.meta.total,10);
 const tech=await list('declaraciones',query({regimen:'Importacion',empresa:'2'},'declaraciones'));assert.equal(tech.meta.total,2);assert.equal(tech.data.reduce((s,d)=>s+d.valor_declarado,0),163000);
 const computers=await list('inventario',query({producto:'1'},'inventario'));assert.equal(computers.data.reduce((s,i)=>s+i.cantidad,0),100);
 const dec=await detail(1);assert.equal(dec.productos.length,2);assert.equal(dec.contenedores.length,2);assert.equal(dec.valor_declarado,121000);
 await assert.rejects(()=>detail(2147483647),{status:404});
 const values=await read('SELECT pa.nombre, SUM(dd.valor_declarado) total FROM detalle_declaracion dd JOIN declaracion d ON d.id_declaracion=dd.id_declaracion JOIN pais pa ON pa.id_pais=d.id_pais_origen GROUP BY pa.id_pais,pa.nombre');assert.equal(values.find(r=>r.nombre==='China').total,167500);assert.equal(values.find(r=>r.nombre==='Corea del Sur').total,85800);
 console.log('Comprobaciones reales de MySQL completadas. No se modificaron registros.');
} catch(error){console.error(error.status?error.message:error.message);process.exitCode=1;} finally {await pool.end();}
