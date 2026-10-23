import {request} from './apiClient.js';
import {getDashboard} from './dashboardService.js';
import {getInventario} from './inventarioService.js';
import {getDeclaraciones} from './declaracionesService.js';
import {getContenedores} from './contenedoresService.js';
import {getBodegas} from './bodegasService.js';
import {getInspecciones} from './inspeccionesService.js';
import {getMovimientos} from './movimientosService.js';
const services={dashboard:getDashboard,inventario:getInventario,declaraciones:getDeclaraciones,contenedores:getContenedores,bodegas:getBodegas,inspecciones:getInspecciones,movimientos:getMovimientos};
export function getResource(path,options){return (services[path.split('/')[1]]||request)(path,options);}
