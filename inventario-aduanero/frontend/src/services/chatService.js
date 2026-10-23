import {request} from './apiClient.js';
export async function sendMessage(message,sessionId){return (await request('/chat',{method:'POST',body:JSON.stringify({message,sessionId})})).data.reply;}
