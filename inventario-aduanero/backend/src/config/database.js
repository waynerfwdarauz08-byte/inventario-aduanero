import mysql from 'mysql2/promise';
import { env } from './env.js';
import { HttpError } from '../utils/HttpError.js';
export const pool = mysql.createPool({ host: env.host, port: env.dbPort, database: env.database,
  user: env.user, password: env.password, connectionLimit: 5, waitForConnections: true,
  queueLimit: 20, connectTimeout: 5000, dateStrings: true, decimalNumbers: true, multipleStatements: false });
export async function read(sql, values = []) {
  if (!env.user) throw new HttpError(503, 'Configure el usuario MySQL de solo lectura en backend/.env.');
  if (!/^\s*SELECT\b/i.test(sql) || /;|\b(INTO|FOR UPDATE|LOCK|SLEEP|BENCHMARK)\b/i.test(sql)) throw new Error('Consulta no permitida');
  try { const [rows] = await pool.query({ sql, values, timeout: 10000 }); return rows; }
  catch { throw new HttpError(503, 'No se pudo consultar MySQL. Revise el servicio y las credenciales privadas.'); }
}
