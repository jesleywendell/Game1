import { useMutation, useQueryClient } from '@tanstack/vue-query'
import { createViagem } from '@/services/api/viagens/createViagem'
import type { IViagemRequest, IViagemResponse } from '@/types/models/IViagemRequest'

type ApiError = {
  message?: { message: string }[]
  error?: string
  detail?: string | { msg: string }[]
}

export function useCreateViagem() {
  const qc = useQueryClient()

  return useMutation<IViagemResponse, Error, IViagemRequest>({
    mutationFn: async (payload) => {
      const res = await createViagem(payload)

      // proteção caso a API padronize erro
      if (res && typeof res === 'object' && 'error' in res) {
        const errVal = (res as Record<string, unknown>).error
        if (typeof errVal === 'string') {
          throw new Error(errVal)
        }
      }
      return res
    },

    onSuccess: async () => {
      await qc.invalidateQueries({ queryKey: ['viagens'] })
    },

    onError: (error: unknown) => {
      let message = 'Não foi possível solicitar a viagem.'
      if (typeof error === 'object' && error !== null) {
        const e = error as ApiError
        message =
          e?.message?.[0]?.message ||
          e?.error ||
          (typeof e?.detail === 'string' && e.detail) ||
          (Array.isArray(e?.detail) && e.detail[0]?.msg) ||
          message
      }
      throw new Error(message)
    },
  })
}
