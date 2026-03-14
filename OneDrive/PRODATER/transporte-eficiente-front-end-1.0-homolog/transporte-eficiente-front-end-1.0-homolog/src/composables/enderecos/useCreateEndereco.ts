import { useMutation } from '@tanstack/vue-query'
import { createEndereco } from '@/services/api/endereco/createEndereco'
import type { IEndereco } from '@/types/models/IEndereco'

export const useCreateEndereco = () => {
  return useMutation<IEndereco, Error, IEndereco>({
    mutationFn: async (data: IEndereco): Promise<IEndereco> => {
      const res = await createEndereco(data)

      if (
        typeof res === 'object' &&
        res !== null &&
        'error' in res &&
        typeof (res as { error?: unknown }).error === 'string'
      ) {
        throw new Error((res as { error: string }).error)
      }

      return res
    },
    // se depois formos listar endereços, aqui a gente invalida a chave correspondente
    onError: (error: unknown) => {
      let msg = 'Erro ao salvar endereço.'
      if (typeof error === 'object' && error !== null) {
        type ApiError = {
          message?: { message: string }[]
          error?: string
          detail?: string | { msg: string }[]
        }
        const e = error as ApiError
        msg =
          e?.message?.[0]?.message ||
          e?.error ||
          (typeof e?.detail === 'string' && e.detail) ||
          (Array.isArray(e?.detail) && e?.detail?.[0]?.msg) ||
          'Erro ao salvar endereço.'
      }
      throw new Error(msg)
    },
  })
}
