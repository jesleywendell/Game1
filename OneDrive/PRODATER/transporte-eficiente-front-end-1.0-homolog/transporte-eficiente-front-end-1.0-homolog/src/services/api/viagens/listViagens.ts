import type { IViagem } from '@/types/models/IViagem'
import { LIST_VIAGENS } from './endpoints'

export type ListViagensParams = {
  skip?: number
  limit?: number
  beneficiario_id?: number
}

export type ListResponse = IViagem[]

export async function listViagens(params: ListViagensParams): Promise<ListResponse> {
  const qs = new URLSearchParams()
  if (params.skip != null) qs.set('skip', String(params.skip))
  if (params.limit != null) qs.set('limit', String(params.limit))
  if (params.beneficiario_id != null) qs.set('beneficiario_id', String(params.beneficiario_id))


  const res = await LIST_VIAGENS.getList(`?${qs.toString()}`)
  return res as ListResponse
}
