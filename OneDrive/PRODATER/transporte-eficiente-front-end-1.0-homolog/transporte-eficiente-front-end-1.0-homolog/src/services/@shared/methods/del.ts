import { handleFetchError } from './patch'
import type { Axios, AxiosError } from 'axios'

/**
 * Faz uma requisição DELETE para a URL especificada com os dados fornecidos.
 *
 * @returns {Promise<T>} Uma promessa que resolve com os dados da resposta da requisição DELETE.
 * @param {Axios} fetchInstance - A instância do fetch a ser usada.
 * @param path - A URL para a qual a requisição DELETE será feita.
 */
export async function del<T>(fetchInstance: Axios, path: string): Promise<T> {
  try {
    const response = await fetchInstance.delete<T>(path)
    return await response.data
  } catch (error: unknown) {
    handleFetchError(error as AxiosError)
  }
}
