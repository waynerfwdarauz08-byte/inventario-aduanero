import { useEffect,useState,useCallback } from 'react';
import { getResource } from '../services/resourceService.js';
export default function useResource(path,params={}){
  const [state,setState]=useState({loading:true,data:null,error:null}),[revision,setRevision]=useState(0);
  const key=JSON.stringify(params);
  useEffect(()=>{const controller=new AbortController();setState({loading:true,data:null,error:null});
    getResource(path,{params:JSON.parse(key),signal:controller.signal}).then(result=>{if(!controller.signal.aborted)setState({loading:false,...result,error:null});}).catch(error=>{if(!controller.signal.aborted)setState({loading:false,data:null,error:error.message});});
    return()=>controller.abort();
  },[path,key,revision]);
  return {...state,retry:useCallback(()=>setRevision(v=>v+1),[])};
}
