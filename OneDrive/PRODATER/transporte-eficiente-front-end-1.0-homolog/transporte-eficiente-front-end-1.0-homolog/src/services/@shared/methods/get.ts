import type { Axios, AxiosError } from 'axios'

/**
 * Envia uma requisição GET para a URL especificada com opções opcionais.
 *
 * @param {Axios} fetchInstance - A instância do fetch a ser usada.
 * @param {string} path - A URL para onde a requisição GET será enviada.
 * @returns {Promise<T>} - Uma promessa que resolve os dados da resposta.
 */
export async function get<T>(fetchInstance: Axios, path: string): Promise<T> {
  try {
    const response = await fetchInstance.get<T>(path)
    return response.data
  } catch (error: unknown) {
    handleFetchError(error as AxiosError)
  }
}

function handleFetchError(error: AxiosError): never {
  // Se não houver `response`, lançamos a mensagem de erro diretamente (como "Network Error")
  if (!error?.response) {
    throw new Error(error?.message)
  }

  // Se houver `response`, lançamos os dados da resposta
  throw error?.response.data
}
