import { useMutation, useQueryClient } from '@tanstack/vue-query'
import { createBeneficiario } from '@/services/api/beneficiario/createBeneficiario'
import type { IBeneficiario } from '@/types/models/IBeneficiario'

export const useCreateBeneficiario = () => {
  const queryClient = useQueryClient()

  return useMutation<IBeneficiario, Error, IBeneficiario>({
    // mutationFn: função que envia os dados para a API
    mutationFn: async (data: IBeneficiario): Promise<IBeneficiario> => {
      const response = await createBeneficiario(data)

      if (
        typeof response === 'object' &&
        response !== null &&
        'error' in response &&
        typeof response.error === 'string'
      ) {
        throw new Error(response.error)
      }

      return response
    },

    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['beneficiarios'] })
    },

    // passa erro pra tratar no componente
    onError: (error: unknown) => {
      let message = 'Erro ao cadastrar beneficiário.'

      if (typeof error === 'object' && error !== null) {
        type ApiError = {
          message?: { message: string }[]
          error?: string
          detail?: string | { msg: string }[]
        }
        const typedError = error as ApiError

        message =
          typedError?.message?.[0]?.message ||
          typedError?.error ||
          (typeof typedError?.detail === 'string' && typedError.detail) ||
          (Array.isArray(typedError?.detail) && typedError?.detail?.[0]?.msg) ||
          'Erro ao cadastrar beneficiário.'
      }

      throw new Error(message)
    },
  })
}
