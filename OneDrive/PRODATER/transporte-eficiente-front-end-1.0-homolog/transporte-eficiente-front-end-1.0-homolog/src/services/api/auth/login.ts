import { TOKEN_ENDPOINT } from '@/services/api/auth/endpoints'

export const loginUsuario = async (payload: { username: string; password: string }) => {
  const formData = new URLSearchParams()
  formData.append('username', payload.username)
  formData.append('password', payload.password)

  return await TOKEN_ENDPOINT.login(formData)
}
