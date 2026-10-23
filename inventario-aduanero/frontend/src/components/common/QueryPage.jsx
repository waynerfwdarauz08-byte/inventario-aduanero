import {useState,useEffect} from 'react';
import {useSearchParams} from 'react-router-dom';
import {Search,SlidersHorizontal,RotateCcw} from 'lucide-react';
import useResource from '../../hooks/useResource.js';
import PageHeader from './PageHeader.jsx';
import ResourceState from './ResourceState.jsx';
import DataTable from './DataTable.jsx';
import Pagination from './Pagination.jsx';
export default function QueryPage({title,description,resource,columns,filters=[],notice,initial={}}){
 const [url,setUrl]=useSearchParams();const current={...initial,...Object.fromEntries(url)};const [draft,setDraft]=useState(current);
 const queryKey=url.toString();
 useEffect(()=>setDraft({...initial,...Object.fromEntries(new URLSearchParams(queryKey))}),[queryKey]);
 const result=useResource('/'+resource,current);const catalogs=useResource('/catalogos');
 const options=(filter)=>filter.catalog?(catalogs.data?.[filter.catalog]||[]).map(x=>[x.id,x.nombre]):(filter.options||[]).map(x=>[x,x]);
 const changePage=page=>setUrl({...current,page:String(page)});
 return <><PageHeader title={title} description={description}><span className="outline-tag"><SlidersHorizontal size={15}/>Consulta de registros</span></PageHeader>{notice&&<p className="info-note">{notice}</p>}<section className="panel"><form className="filters" onSubmit={e=>{e.preventDefault();setUrl({...draft,page:'1'});}}><label className="search-field">Buscar<div><Search size={17}/><input value={draft.search||''} maxLength={200} onChange={e=>setDraft({...draft,search:e.target.value})} placeholder="Buscar en los registros…"/></div></label>{filters.map(f=><label key={f.key}>{f.label}{f.type==='date'?<input type="date" value={draft[f.key]||''} onChange={e=>setDraft({...draft,[f.key]:e.target.value})}/>:<select value={draft[f.key]||''} onChange={e=>setDraft({...draft,[f.key]:e.target.value})}><option value="">Todos</option>{options(f).map(([v,t])=><option key={v} value={v}>{t}</option>)}</select>}</label>)}<label>Ordenar<select value={draft.sort||''} onChange={e=>setDraft({...draft,sort:e.target.value})}><option value="">Predeterminado</option>{columns.filter(c=>c.sort).map(c=><option key={c.key} value={c.sort}>{c.label}</option>)}</select></label><label>Dirección<select value={draft.direction||'desc'} onChange={e=>setDraft({...draft,direction:e.target.value})}><option value="desc">Descendente</option><option value="asc">Ascendente</option></select></label><label>Por página<select value={draft.pageSize||'10'} onChange={e=>setDraft({...draft,pageSize:e.target.value})}>{[10,25,50,100].map(n=><option key={n}>{n}</option>)}</select></label><button className="button" type="submit">Aplicar filtros</button><button className="button secondary" type="button" onClick={()=>{setDraft(initial);setUrl(initial);}}><RotateCcw size={15}/>Limpiar</button></form>{catalogs.error&&filters.some(f=>f.catalog)&&<div className="catalog-error" role="alert">No se cargaron las opciones de filtros. <button onClick={catalogs.retry}>Reintentar catálogos</button></div>}<div className="panel-heading"><h2>{title}</h2><span className="muted">Datos de MySQL</span></div><ResourceState resource={result}><DataTable columns={columns} rows={result.data||[]} caption={title}/><Pagination meta={result.meta} onChange={changePage}/></ResourceState></section></>;
}
