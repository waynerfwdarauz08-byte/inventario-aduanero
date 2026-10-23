import {Link} from 'react-router-dom';
export default function NotFoundPage(){return <div className="state"><span className="eyebrow">ERROR 404</span><h1>Página no encontrada</h1><p>La dirección solicitada no existe.</p><Link className="button" to="/">Volver al resumen</Link></div>;}
