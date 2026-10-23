import {Link} from 'react-router-dom';
import StatusBadge from '../common/StatusBadge.jsx';
import {date,money} from '../../utils/format.js';
export const declarationColumns=[{key:'numero',label:'Declaración',sort:'numero',render:r=><Link className="table-link" to={'/declaraciones/'+r.id_declaracion}>{r.numero} ↗</Link>},{key:'fecha',label:'Fecha',sort:'fecha',render:r=>date(r.fecha)},{key:'regimen',label:'Régimen'},{key:'estado',label:'Estado',render:r=><StatusBadge value={r.estado}/>},{key:'importador',label:'Importador'},{key:'agente',label:'Agente'},{key:'pais',label:'País de origen'},{key:'valor_declarado',label:'Valor declarado',sort:'valor',render:r=>money(r.valor_declarado)}];
