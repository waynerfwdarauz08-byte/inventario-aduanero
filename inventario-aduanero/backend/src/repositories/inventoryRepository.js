import { read } from '../config/database.js';
import { HttpError } from '../utils/HttpError.js';
const declarationsFrom = `FROM declaracion d JOIN importador imp ON imp.id_importador=d.id_importador
 JOIN agente_aduanal a ON a.id_agente=d.id_agente JOIN pais pa ON pa.id_pais=d.id_pais_origen
 LEFT JOIN (SELECT id_declaracion, SUM(valor_declarado) valor_declarado FROM detalle_declaracion GROUP BY id_declaracion) v ON v.id_declaracion=d.id_declaracion`;
const inventoryFrom = `FROM inventario i JOIN producto p ON p.id_producto=i.id_producto JOIN bodega b ON b.id_bodega=i.id_bodega
 JOIN detalle_declaracion dd ON dd.id_declaracion=i.id_declaracion AND dd.id_producto=i.id_producto
 JOIN declaracion d ON d.id_declaracion=dd.id_declaracion JOIN pais pa ON pa.id_pais=d.id_pais_origen`;
export const resources = {
  declaraciones: { select: 'd.*, imp.razon_social importador, a.nombre agente, pa.nombre pais, COALESCE(v.valor_declarado,0) valor_declarado', from: declarationsFrom,
    search: ['d.numero','imp.razon_social'], filters: {regimen:'d.regimen',estado:'d.estado',empresa:'d.id_importador'}, date:'d.fecha', sorts:{fecha:'d.fecha',numero:'d.numero',valor:'valor_declarado'}, defaultSort:'fecha', key:'d.id_declaracion' },
  inventario: { select:'i.*, p.descripcion producto, p.unidad_medida, b.nombre bodega, d.numero declaracion, pa.nombre pais', from:inventoryFrom,
    search:['p.descripcion','d.numero','b.nombre'], filters:{producto:'i.id_producto',bodega:'i.id_bodega',pais:'d.id_pais_origen',estado:'i.estado'}, date:'i.fecha_ingreso', sorts:{fecha:'i.fecha_ingreso',cantidad:'i.cantidad',producto:'p.descripcion'}, defaultSort:'fecha',key:'i.id_inventario' },
  contenedores: {select:'c.*, d.numero declaracion, d.regimen, pa.nombre pais',from:'FROM contenedor c JOIN declaracion d ON d.id_declaracion=c.id_declaracion JOIN pais pa ON pa.id_pais=d.id_pais_origen',search:['c.numero','d.numero'],filters:{pais:'d.id_pais_origen',regimen:'d.regimen'},sorts:{numero:'c.numero',peso:'c.peso_kg'},defaultSort:'numero',key:'c.id_contenedor'},
  bodegas: {select:'b.*, (SELECT COUNT(*) FROM inventario i WHERE i.id_bodega=b.id_bodega) lotes, (SELECT COUNT(DISTINCT i.id_producto) FROM inventario i WHERE i.id_bodega=b.id_bodega AND i.cantidad>0) productos_con_stock',from:'FROM bodega b',search:['b.nombre','b.ubicacion'],filters:{},sorts:{nombre:'b.nombre',capacidad:'b.capacidad_m3'},defaultSort:'nombre',key:'b.id_bodega'},
  inspecciones: {select:'ins.*, d.numero declaracion, imp.razon_social importador, f.nombre funcionario, sup.nombre supervisor',from:'FROM inspeccion ins JOIN declaracion d ON d.id_declaracion=ins.id_declaracion JOIN importador imp ON imp.id_importador=d.id_importador JOIN funcionario f ON f.id_funcionario=ins.id_funcionario LEFT JOIN funcionario sup ON sup.id_funcionario=f.id_supervisor',search:['d.numero','imp.razon_social','ins.observaciones'],filters:{resultado:'ins.resultado',funcionario:'ins.id_funcionario'},date:'ins.fecha',sorts:{fecha:'ins.fecha',resultado:'ins.resultado'},defaultSort:'fecha',key:'ins.id_inspeccion'},
  movimientos: {select:'m.*, p.descripcion producto, p.unidad_medida, b.nombre bodega, dest.nombre bodega_destino',from:'FROM movimiento m JOIN inventario i ON i.id_inventario=m.id_inventario JOIN producto p ON p.id_producto=i.id_producto JOIN bodega b ON b.id_bodega=i.id_bodega LEFT JOIN inventario destino ON destino.id_inventario=m.id_inventario_destino LEFT JOIN bodega dest ON dest.id_bodega=destino.id_bodega',search:['p.descripcion','m.observaciones','b.nombre'],filters:{tipo:'m.tipo',producto:'i.id_producto',bodega:'i.id_bodega'},date:'m.fecha',sorts:{fecha:'m.fecha',tipo:'m.tipo'},defaultSort:'fecha',key:'m.id_movimiento'},
};
export function buildList(name,q,extra={}) {
  const r=resources[name], values=[], conditions=[];
  const add=(sql,value)=>{conditions.push(sql);values.push(value);};
  const supported=new Set(['page','pageSize','search','sort','direction',...Object.keys(r.filters),...(r.date?['desde','hasta']:[]),...(name==='inventario'?['disponibilidad']:[])]);
  for(const k of Object.keys(q)) if(!supported.has(k)) throw new HttpError(400,`Filtro no disponible: ${k}.`);
  for(const [key,col] of Object.entries(r.filters)) if(q[key]) add(`${col}=?`,q[key]);
  if(q.search) {conditions.push(`(${r.search.map(c=>`${c} LIKE ?`).join(' OR ')})`);values.push(...r.search.map(()=>`%${q.search}%`));}
  if(q.desde) add(`${r.date} >= ?`,q.desde);
  if(q.hasta) add(`${r.date} < DATE_ADD(?, INTERVAL 1 DAY)`,q.hasta);
  if(q.disponibilidad) conditions.push(q.disponibilidad==='con-stock'?'i.cantidad>0':'i.cantidad=0');
  if(extra.declaracion) add('i.id_declaracion=?',extra.declaracion);
  const order=r.sorts[q.sort||r.defaultSort]; if(!order) throw new HttpError(400,'Ordenamiento inválido.');
  const from=`${r.from}${conditions.length?' WHERE '+conditions.join(' AND '):''}`;
  return {count:`SELECT COUNT(*) total ${from}`,sql:`SELECT ${r.select} ${from} ORDER BY ${order} ${q.direction==='asc'?'ASC':'DESC'}, ${r.key} DESC LIMIT ? OFFSET ?`,values};
}
export async function list(name,q,extra) {
  const b=buildList(name,q,extra);
  const [counts,data]=await Promise.all([read(b.count,b.values),read(b.sql,[...b.values,q.pageSize,(q.page-1)*q.pageSize])]);
  return {data,meta:{page:q.page,pageSize:q.pageSize,total:counts[0].total,totalPages:Math.ceil(counts[0].total/q.pageSize)}};
}
export async function detail(id) {
  const [general]=await read(`SELECT ${resources.declaraciones.select} ${declarationsFrom} WHERE d.id_declaracion=?`,[id]);
  if(!general) throw new HttpError(404,'Declaración no encontrada.');
  const [productos,contenedores,inspecciones,lotes]=await Promise.all([
    read('SELECT dd.*, p.descripcion producto, p.unidad_medida, pa.codigo partida, pa.porcentaje_arancel FROM detalle_declaracion dd JOIN producto p ON p.id_producto=dd.id_producto JOIN partida_arancelaria pa ON pa.id_partida=p.id_partida WHERE dd.id_declaracion=?',[id]),
    read(`SELECT ${resources.contenedores.select} ${resources.contenedores.from} WHERE c.id_declaracion=?`,[id]),
    read(`SELECT ${resources.inspecciones.select} ${resources.inspecciones.from} WHERE ins.id_declaracion=?`,[id]),
    read(`SELECT ${resources.inventario.select} ${inventoryFrom} WHERE i.id_declaracion=?`,[id]),
  ]);return {...general,productos,contenedores,inspecciones,lotes};
}
export async function dashboard() {
  const [totals,regimenes,paises,recientes]=await Promise.all([
    read(`SELECT (SELECT COUNT(*) FROM declaracion) declaraciones, (SELECT COUNT(*) FROM contenedor) contenedores,
      (SELECT COUNT(*) FROM inventario WHERE estado='Retenido' AND cantidad>0) retenidos,
      (SELECT COUNT(*) FROM inspeccion) inspecciones, (SELECT COUNT(*) FROM inspeccion WHERE resultado='Con observaciones') con_observaciones,
      (SELECT COALESCE(SUM(valor_declarado),0) FROM detalle_declaracion) valor_declarado`),
    read('SELECT regimen nombre, COUNT(*) total FROM declaracion GROUP BY regimen ORDER BY total DESC'),
    read("SELECT pa.nombre, COUNT(*) total FROM contenedor c JOIN declaracion d ON d.id_declaracion=c.id_declaracion JOIN pais pa ON pa.id_pais=d.id_pais_origen WHERE d.regimen <> 'Exportacion' GROUP BY pa.id_pais,pa.nombre ORDER BY total DESC,pa.nombre"),
    read(`SELECT ${resources.declaraciones.select} ${declarationsFrom} ORDER BY d.fecha DESC,d.id_declaracion DESC LIMIT 5`),
  ]);return {...totals[0],regimenes,paises,recientes};
}
export async function catalogos() {
  const definitions={productos:'SELECT id_producto id, descripcion nombre FROM producto ORDER BY descripcion',bodegas:'SELECT id_bodega id,nombre FROM bodega ORDER BY nombre',paises:'SELECT id_pais id,nombre FROM pais ORDER BY nombre',empresas:'SELECT id_importador id,razon_social nombre FROM importador ORDER BY razon_social',funcionarios:'SELECT id_funcionario id,nombre FROM funcionario ORDER BY nombre'};
  return Object.fromEntries(await Promise.all(Object.entries(definitions).map(async([key,sql])=>[key,await read(sql)])));
}
export async function existsBodega(id) {return (await read('SELECT id_bodega FROM bodega WHERE id_bodega=?',[id])).length>0;}
