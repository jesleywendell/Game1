import { apiMethods } from '@/services/@shared/api.interface'
import { fetchConfig } from '@/services/axiosClient'

const LIST_BENEFICIARIOS = apiMethods(fetchConfig, 'beneficiario/')

const CREATE_BENEFICIARIO = apiMethods(fetchConfig, 'beneficiario/')

const READ_BENEFICIARIO = (beneficiarioId: string) =>
  apiMethods(fetchConfig, `beneficiario/${beneficiarioId}`)

const UPDATE_BENEFICIARIO = (beneficiarioId: string) =>
  apiMethods(fetchConfig, `beneficiario/${beneficiarioId}`)

const DELETE_BENEFICIARIO = (beneficiarioId: string) =>
  apiMethods(fetchConfig, `beneficiario/${beneficiarioId}`)

export {
  LIST_BENEFICIARIOS,
  CREATE_BENEFICIARIO,
  READ_BENEFICIARIO,
  UPDATE_BENEFICIARIO,
  DELETE_BENEFICIARIO,
}
