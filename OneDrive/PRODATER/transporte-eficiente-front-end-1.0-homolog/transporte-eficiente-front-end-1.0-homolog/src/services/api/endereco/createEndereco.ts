import type { IEndereco } from '@/types/models/IEndereco'
import { CREATE_ENDERECO } from './endpoints'

export const createEndereco = async (data: IEndereco) => {
  return await CREATE_ENDERECO.create(data)
}
