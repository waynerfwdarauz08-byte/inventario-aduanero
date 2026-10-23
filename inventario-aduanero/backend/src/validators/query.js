import { HttpError } from '../utils/HttpError.js';
export const enums = {
  regimen: ['Importacion','Exportacion','Transito','Deposito'],
  estadoDeclaracion: ['Retenida','En revision','Liberada','Rechazada'],
  estadoInventario: ['Retenido','En revision','Liberado'],
  resultado: ['Sin observaciones','Con observaciones','No conforme'], tipo: ['Entrada','Salida','Traslado'],
};
const bad = (s) => { throw new HttpError(400, s); };
export function id(value) {
  if (typeof value !== 'string' || !/^[1-9]\d{0,9}$/.test(value) || Number(value) > 2147483647) bad('ID inválido.');
  return Number(value);
}
export function query(input, resource) {
  const allowed = ['page','pageSize','search','sort','direction','desde','hasta','regimen','estado','producto','bodega','pais','empresa','funcionario','resultado','tipo','disponibilidad'];
  for (const [k,v] of Object.entries(input)) if (!allowed.includes(k) || typeof v !== 'string' || v.length > 200) bad('Parámetro inválido.');
  const q = { ...input };
  for (const [key, fallback, max] of [['page',1,100000],['pageSize',10,100]]) {
    if (q[key] !== undefined && !/^[1-9]\d*$/.test(q[key])) bad('Paginación inválida.');
    q[key] = Number(q[key] || fallback); if (q[key] > max) bad(`Máximo permitido para ${key}: ${max}.`);
  }
  for (const key of ['producto','bodega','pais','empresa','funcionario']) if (q[key]) q[key] = id(q[key]);
  for (const key of ['desde','hasta']) if (q[key]) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(q[key]) || Number(q[key].slice(0,4)) < 1000 || !Number.isFinite(Date.parse(q[key])) || new Date(q[key]).toISOString().slice(0,10) !== q[key]) bad('Fecha inválida.');
  }
  if (q.desde && q.hasta && q.desde > q.hasta) bad('La fecha inicial debe ser anterior a la final.');
  for (const key of ['regimen','resultado','tipo']) if (q[key] && !enums[key].includes(q[key])) bad(`${key} inválido.`);
  if (q.estado && !(resource === 'inventario' ? enums.estadoInventario : enums.estadoDeclaracion).includes(q.estado)) bad('Estado inválido.');
  if (q.disponibilidad && !['con-stock','sin-stock'].includes(q.disponibilidad)) bad('Disponibilidad inválida.');
  if (q.direction && !['asc','desc'].includes(q.direction)) bad('Dirección inválida.');
  return q;
}
export function chat(body) {
  if (!body || typeof body.message !== 'string' || !body.message.trim() || body.message.length > 4000) bad('Escriba una pregunta de hasta 4000 caracteres.');
  if (typeof body.sessionId !== 'string' || !/^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/i.test(body.sessionId)) bad('Sesión inválida. Inicie una nueva conversación.');
  return { message: body.message.trim(), sessionId: body.sessionId };
}
