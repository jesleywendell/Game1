import type { IViagemRequest, IViagemResponse } from '@/types/models/IViagemRequest'
import { CREATE_VIAGEM } from './endpoints'

export async function createViagem(
  data: IViagemRequest,
): Promise<IViagemResponse> {
  return await CREATE_VIAGEM.create(data)
}
