import type { IBeneficiario } from '@/types/models/IBeneficiario'
import { CREATE_BENEFICIARIO } from './endpoints'

export const createBeneficiario = async (data: IBeneficiario) => {
  return await CREATE_BENEFICIARIO.create(data)
}
