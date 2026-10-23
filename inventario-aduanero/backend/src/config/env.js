import dotenv from 'dotenv';
import { fileURLToPath } from 'node:url';
dotenv.config({ path: fileURLToPath(new URL('../../.env', import.meta.url)), quiet: true });
const integer = (name, fallback, min, max) => {
  const n = Number(process.env[name] || fallback);
  if (!Number.isInteger(n) || n < min || n > max) throw new Error(`Configuración inválida: ${name}`);
  return n;
};
export const env = {
  port: integer('PORT', 3001, 1, 65535), host: process.env.DB_HOST || '127.0.0.1',
  dbPort: integer('DB_PORT', 3306, 1, 65535), database: process.env.DB_NAME || 'aduana_wayner',
  user: process.env.DB_USER || '', password: process.env.DB_PASSWORD || '',
  origin: process.env.FRONTEND_ORIGIN || 'http://127.0.0.1:5173',
  webhook: process.env.N8N_WEBHOOK_URL || '', secret: process.env.N8N_WEBHOOK_SECRET || '',
  timeout: integer('N8N_TIMEOUT_MS', 60000, 1000, 120000),
};
if (env.database !== 'aduana_wayner') throw new Error('Esta aplicación requiere aduana_wayner; no utilice una copia de prueba.');
