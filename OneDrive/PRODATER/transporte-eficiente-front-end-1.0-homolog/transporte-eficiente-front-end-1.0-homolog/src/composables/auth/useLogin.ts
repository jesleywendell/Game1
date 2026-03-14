import { ref } from 'vue'
import { useRouter } from 'vue-router'
import * as yup from 'yup'
import { loginSchema } from '@/schemas/LoginSchema'
import { loginUsuario } from '@/services/api/auth/login'
import { useAuth } from './useAuth'
import Cookies from 'js-cookie'

// Definindo tipo para erro da API
type ApiError = {
  message?: { message: string }[]
  error?: string
  detail?: string | { msg: string }[]
}

export const useLogin = () => {
  const username = ref('')
  const password = ref('')
  const checked = ref(false)

  const errors = ref<Record<string, string>>({
    username: '',
    password: '',
    checked: '',
  })

  const isLoading = ref(false)
  const showAlertError = ref(false)
  const errorMessage = ref('')

  const router = useRouter()

  // Lógica principal de login
  const handleLogin = async () => {
    showAlertError.value = false
    isLoading.value = true
    errors.value = { username: '', password: '', checked: '' }

    const formValues = {
      username: username.value,
      password: password.value,
      checked: checked.value,
    }

    // Validação
    try {
      await loginSchema.validate(formValues, { abortEarly: false })
    } catch (validationError: unknown) {
      if (validationError instanceof yup.ValidationError) {
        validationError.inner.forEach((err) => {
          if (err.path) {
            errors.value[err.path] = err.message
          }
        })
      }
      isLoading.value = false
      return
    }

    // Requisição de login
    try {
      const payload = {
        username: username.value,
        password: password.value,
      }

      const response = await loginUsuario(payload)

      if (response.access_token) {
        Cookies.set('access_token', response.access_token)

        const { loadUserFromToken } = useAuth()
        loadUserFromToken()

        router.push('/cadastro-beneficiario')
      } else {
        if (!('access_token' in response)) {
          const backendMsg =
            (response?.detail as string) ||
            (Array.isArray(response?.message) && response.message[0]?.message) ||
            response?.error

          throw new Error(backendMsg || 'Token de acesso não retornado.')
        }
      }
    } catch (error: unknown) {
      console.error('Erro ao fazer login:', error)

      const typedError = error as ApiError
      const msg =
        typedError?.message?.[0]?.message ||
        typedError?.error ||
        (typeof typedError?.detail === 'string' && typedError.detail) ||
        (Array.isArray(typedError?.detail) && typedError?.detail?.[0]?.msg) ||
        'Erro ao tentar fazer login.'

      errorMessage.value = msg
      showAlertError.value = true
    } finally {
      isLoading.value = false
    }
  }

  return {
    username,
    password,
    checked,
    errors,
    isLoading,
    showAlertError,
    errorMessage,
    handleLogin,
  }
}
