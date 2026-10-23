import {Link} from 'react-router-dom';
import StatusBadge from '../common/StatusBadge.jsx';
import {date} from '../../utils/format.js';
export const inspectionColumns=[{key:'fecha',label:'Fecha',sort:'fecha',render:r=>date(r.fecha)},{key:'declaracion',label:'Declaración',render:r=><Link to={'/declaraciones/'+r.id_declaracion}>{r.declaracion}</Link>},{key:'importador',label:'Importador'},{key:'resultado',label:'Resultado',sort:'resultado',render:r=><StatusBadge value={r.resultado}/>},{key:'funcionario',label:'Funcionario'},{key:'supervisor',label:'Supervisor'},{key:'observaciones',label:'Observaciones'}];
