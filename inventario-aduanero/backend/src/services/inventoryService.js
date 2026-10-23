import * as repository from '../repositories/inventoryRepository.js';
import { HttpError } from '../utils/HttpError.js';
export const list=repository.list;
export const detail=repository.detail;
export const dashboard=repository.dashboard;
export const catalogos=repository.catalogos;
export async function bodega(id,q) {
  if(!await repository.existsBodega(id)) throw new HttpError(404,'Bodega no encontrada.');
  return repository.list('inventario',{...q,bodega:id});
}
