import type { Axios, AxiosError } from 'axios'

/**
 * Realiza uma requisição HTTP POST para a URL especificada com os dados fornecidos.
 *
 * @param {Axios} fetchInstance - A instância do fetch a ser usada.
 * @param {string} url - A URL para enviar a requisição POST.
 * @param {*} payload - Os dados para enviar no corpo da requisição POST.
 * @returns {Promise<T>} - Uma promessa que resolve com os dados da resposta do servidor.
 */
export async function post<T>(fetchInstance: Axios, url: string, payload: unknown): Promise<T> {
  try {
    const response = await fetchInstance.post<T>(url, payload)
    return await response.data
  } catch (error: unknown) {
    throw handleFetchError(error as AxiosError)
  }
}

/**
 * Manipula erros de requisição HTTP, extraindo a mensagem de erro apropriada.
 *
 * @param {FetchError} error - O erro lançado pela requisição HTTP.
 * @returns {Error | IResponseError} - A mensagem de erro processada.
 */
function handleFetchError(error: AxiosError): unknown {
  if (error.response) {
    return error.response.data || 'Erro desconhecido do servidor'
  } else {
    return {
      error: 'Network Error',
      message: [
        {
          context: 'Network Error',
          error: 'Network Error',
          message: 'Erro ao tentar se conectar ao servidor',
          statusCode: 500,
        },
      ],
      statusCode: 500,
    }
  }
}
