import type { Axios, AxiosError } from 'axios'

export function handleFetchError(error: AxiosError): never {
  // Se não houver `response`, lançamos a mensagem de erro diretamente (como "Network Error")
  if (!error?.response) {
    throw new Error(error?.message)
  }

  // Se houver `response`, lançamos os dados da resposta
  throw error?.response.data
}

/**
 * Envia uma requisição PATCH para a URL especificada com os dados fornecidos.
 *
 * @param {Axios} fetchInstance - A instância do fetch a ser usada.
 * @param {string} path - O caminho para enviar a requisição PATCH.
 * @param {*} payload - Os dados a serem enviados no corpo da requisição.
 * @returns {Promise<T>} Uma promessa que resolve para os dados da resposta da requisição PATCH.
 */
export async function patch<T>(fetchInstance: Axios, path: string, payload?: unknown): Promise<T> {
  try {
    const response = await fetchInstance.patch<T>(path, payload)
    return await response.data
  } catch (error: unknown) {
    handleFetchError(error as AxiosError)
  }
}
