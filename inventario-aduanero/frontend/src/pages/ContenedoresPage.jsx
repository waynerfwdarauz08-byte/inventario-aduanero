import QueryPage from '../components/common/QueryPage.jsx';
import {number} from '../utils/format.js';
import {Link} from 'react-router-dom';
export const containerColumns=[{key:'numero',label:'Contenedor',sort:'numero'},{key:'tipo',label:'Tipo'},{key:'peso_kg',label:'Peso (kg)',sort:'peso',render:r=>number(r.peso_kg)},{key:'declaracion',label:'Declaración',render:r=><Link to={'/declaraciones/'+r.id_declaracion}>{r.declaracion}</Link>},{key:'pais',label:'País'},{key:'regimen',label:'Régimen'}];
export default function ContenedoresPage(){return <QueryPage title="Contenedores" description="Trazabilidad de contenedores y su declaración aduanera." resource="contenedores" columns={containerColumns} filters={[{key:'pais',label:'País',catalog:'paises'},{key:'regimen',label:'Régimen',options:['Importacion','Exportacion','Transito','Deposito']}]}/>;}
