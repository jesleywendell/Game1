import type { Axios, AxiosError } from 'axios'

/**
 * Manipula erros de requisição HTTP lançando o erro apropriado.
 *
 * @param {FetchError} error - O erro lançado pela requisição HTTP.
 * @throws {Error} O erro processado.
 */
function handleFetchError(error: AxiosError): never {
  // Se não houver `response`, lançamos a mensagem de erro diretamente (como "Network Error")
  if (!error.response) {
    throw new Error(error.message)
  }

  // Se houver `response`, lançamos os dados da resposta
  throw error.response.data
}

/**
 * Faz uma requisição PUT para a URL especificada com os dados fornecidos.
 *
 * @param {Axios} fetchInstance - A instância do fetch a ser usada.
 * @param {string} url - A URL para fazer a requisição PUT.
 * @param {*} payload - Os dados para enviar com a requisição PUT.
 * @returns {Promise<T>} Uma promessa que resolve com os dados da resposta da requisição PUT.
 */
export async function put<T>(fetchInstance: Axios, url: string, payload: unknown): Promise<T> {
  try {
    const response = await fetchInstance.put<T>(url, payload)
    return await response.data
  } catch (error: unknown) {
    handleFetchError(error as AxiosError)
  }
}
