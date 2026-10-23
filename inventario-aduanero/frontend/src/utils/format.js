export const number=v=>new Intl.NumberFormat('es-CR',{maximumFractionDigits:3}).format(Number(v));
export const money=v=>new Intl.NumberFormat('es-CR',{style:'currency',currency:'USD',currencyDisplay:'code'}).format(Number(v));
export function date(v){if(!v)return '—';const [day,time]=String(v).split(' ');const [y,m,d]=day.split('-');return `${d}/${m}/${y}${time?' · '+time.slice(0,5):''}`;}
