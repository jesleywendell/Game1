import Cookies from 'js-cookie'
import { jwtDecode } from 'jwt-decode'
import type { JwtPayload } from '@/types/jwt'
import { useUserStore } from '@/stores/user'

export const useAuth = () => {
  const userStore = useUserStore()

  const getToken = (): string | undefined => {
    return Cookies.get('access_token')
  }

  const decodeToken = (token: string): JwtPayload | null => {
    try {
      return jwtDecode<JwtPayload>(token)
    } catch (error) {
      console.error('Erro ao decodificar token:', error)
      return null
    }
  }

  const isAuthenticated = (): boolean => {
    const token = getToken()
    if (!token) return false

    const decoded = decodeToken(token)
    if (!decoded || !decoded.exp) return false

    const now = Date.now() / 1000
    return decoded.exp > now
  }

  const loadUserFromToken = () => {
    const token = getToken()
    if (!token) return

    const decoded = decodeToken(token)

    console.log('🔑 Token decodificado:', decoded)

    if (decoded) {
      userStore.setUser({
        sub: decoded.sub,
        exp: decoded.exp,
      })
    }
  }

  const logout = () => {
    Cookies.remove('access_token')
    userStore.setUser(null) // limpa usuário no store
    window.location.href = '/' // redireciona para a home
  }

  return {
    getToken,
    decodeToken,
    isAuthenticated,
    loadUserFromToken,
    logout,
  }
}
