import { apiMethods } from '@/services/@shared/api.interface'
import { fetchConfig } from '@/services/axiosClient'

const LIST_VIAGENS = apiMethods(fetchConfig, 'viagem/')

const CREATE_VIAGEM = apiMethods(fetchConfig, 'viagem/')

const READ_VIAGEM = (viagemId: string) => apiMethods(fetchConfig, `viagem/${viagemId}`)

const UPDATE_VIAGEM = (viagemId: string) => apiMethods(fetchConfig, `viagem/${viagemId}`)

const DELETE_VIAGEM = (viagemId: string) => apiMethods(fetchConfig, `viagem/${viagemId}`)

export { CREATE_VIAGEM, LIST_VIAGENS, READ_VIAGEM, UPDATE_VIAGEM, DELETE_VIAGEM }
