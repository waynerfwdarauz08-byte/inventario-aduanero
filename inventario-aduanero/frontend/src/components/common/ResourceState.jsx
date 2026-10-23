import { AlertCircle,RefreshCw,Database } from 'lucide-react';
export default function ResourceState({resource,children}){
  if(resource.loading)return <div className="state" role="status"><RefreshCw className="spin"/><h3>Consultando información</h3><p>Obteniendo los datos de la base local…</p></div>;
  if(resource.error)return <div className="state error" role="alert"><AlertCircle size={30}/><h3>No se pudo cargar la información</h3><p>{resource.error}</p><button className="button" onClick={resource.retry}><RefreshCw size={16}/>Reintentar</button></div>;
  if(!resource.data)return <div className="state"><Database/><p>Sin información disponible.</p></div>;
  return children;
}
