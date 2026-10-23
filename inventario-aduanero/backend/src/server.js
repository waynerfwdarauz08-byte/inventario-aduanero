import app from './app.js';
import { env } from './config/env.js';
import { pool } from './config/database.js';
const server=app.listen(env.port,'127.0.0.1',()=>console.log(`API local: http://127.0.0.1:${env.port}/api/health`));
server.on('error',()=>{console.error('No se pudo iniciar la API. Revise PORT.');process.exitCode=1;});
for(const signal of ['SIGINT','SIGTERM']) process.on(signal,()=>server.close(async()=>{await pool.end();process.exit(0);}));
