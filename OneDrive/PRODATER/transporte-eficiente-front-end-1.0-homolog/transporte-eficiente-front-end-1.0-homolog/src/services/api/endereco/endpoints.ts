import { apiMethods } from '@/services/@shared/api.interface'
import { fetchConfig } from '@/services/axiosClient'

const LIST_ENDERECOS = apiMethods(fetchConfig, 'endereco/')

const CREATE_ENDERECO = apiMethods(fetchConfig, 'endereco/')

const READ_ENDERECO = (enderecoId: string) => apiMethods(fetchConfig, `endereco/${enderecoId}`)

const UPDATE_ENDERECO = (enderecoId: string) => apiMethods(fetchConfig, `endereco/${enderecoId}`)

const DELETE_ENDERECO = (enderecoId: string) => apiMethods(fetchConfig, `endereco/${enderecoId}`)

export { LIST_ENDERECOS, CREATE_ENDERECO, READ_ENDERECO, UPDATE_ENDERECO, DELETE_ENDERECO }
