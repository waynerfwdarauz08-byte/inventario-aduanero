import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const vite = path.join(root, 'node_modules/vite/bin/vite.js');
if (!existsSync(vite)) {
  console.error('Faltan dependencias. Entre en inventario-aduanero y ejecute npm ci.');
  process.exit(1);
}

const children = [];
let stopping = false;
function stop(code = 0) {
  if (stopping) return;
  stopping = true;
  process.exitCode = code;
  for (const child of children) {
    if (!child.pid || child.exitCode !== null) continue;
    if (process.platform === 'win32') {
      // Solo se detienen los procesos creados por este lanzador y sus hijos.
      spawn('taskkill', ['/PID', String(child.pid), '/T', '/F'], { windowsHide: true, stdio: 'ignore' });
    } else child.kill('SIGTERM');
  }
}

for (const [name, cwd, args] of [
  ['Backend', 'backend', ['--watch', 'src/server.js']],
  ['Frontend', 'frontend', [vite, '--host', '127.0.0.1']],
]) {
  const child = spawn(process.execPath, args, { cwd: path.join(root, cwd), stdio: 'inherit', windowsHide: true });
  children.push(child);
  child.on('error', () => { console.error(`No se pudo iniciar ${name}.`); stop(1); });
  child.on('exit', code => {
    if (!stopping) { console.error(`${name} se detuvo. Revise el mensaje anterior.`); stop(code || 1); }
  });
}
console.log('Iniciando API y aplicación. Abra http://127.0.0.1:5173 cuando Vite esté listo.');
console.log('Ctrl+C detiene ambos servicios. n8n se inicia por separado.');
process.on('SIGINT', () => stop());
process.on('SIGTERM', () => stop());
