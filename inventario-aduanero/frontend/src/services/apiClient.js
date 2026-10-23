const base=import.meta.env.VITE_API_BASE_URL||'http://127.0.0.1:3001/api';
export async function request(path,{params,signal,...options}={}){
  const query=new URLSearchParams(Object.entries(params||{}).filter(([,v])=>v!==''&&v!==undefined));
  let response;
  try{response=await fetch(`${base}${path}${query.size?'?'+query:''}`,{...options,signal:signal||AbortSignal.timeout(70000),headers:{'Content-Type':'application/json',...options.headers}});}
  catch(e){if(e.name==='AbortError')throw e;throw new Error('No se pudo conectar con la API local. Compruebe que el backend esté iniciado.');}
  const data=await response.json().catch(()=>null);
  if(!response.ok||!data?.success)throw new Error(data?.error||'Respuesta inválida del servidor.');
  return data;
}
