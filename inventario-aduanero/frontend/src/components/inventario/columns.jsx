import {Link} from 'react-router-dom';
import StatusBadge from '../common/StatusBadge.jsx';
import {date,number} from '../../utils/format.js';
export const inventoryColumns=[{key:'id_inventario',label:'Lote',render:r=><strong>#{r.id_inventario}</strong>},{key:'producto',label:'Producto',sort:'producto'},{key:'cantidad',label:'Stock actual',sort:'cantidad',render:r=>number(r.cantidad)},{key:'unidad_medida',label:'Unidad'},{key:'bodega',label:'Bodega'},{key:'declaracion',label:'Declaración',render:r=><Link className="table-link" to={'/declaraciones/'+r.id_declaracion}>{r.declaracion}</Link>},{key:'pais',label:'País'},{key:'estado',label:'Estado',render:r=><StatusBadge value={r.estado}/>},{key:'fecha_ingreso',label:'Ingreso',sort:'fecha',render:r=>date(r.fecha_ingreso)}];
