import { apiMethods } from '@/services/@shared/api.interface'
import { fetchConfig } from '@/services/axiosClient'

const TOKEN_ENDPOINT = apiMethods(fetchConfig, 'login/access-token')
const TEST_TOKEN_ENDPOINT = apiMethods(fetchConfig, 'login/test-token')
const PASSWORD_RECOVERY_ENDPOINT = (email: string) => apiMethods(fetchConfig, `password-recovery/${email}`)
const RESET_PASSWORD_ENDPOINT = apiMethods(fetchConfig, 'reset-password')
const PASSWORD_RECOVERY_HTML_ENDPOINT = (email: string) => apiMethods(fetchConfig, `password-recovery-html-content/${email}`)

export {
  TOKEN_ENDPOINT,
  TEST_TOKEN_ENDPOINT,
  PASSWORD_RECOVERY_ENDPOINT,
  RESET_PASSWORD_ENDPOINT,
  PASSWORD_RECOVERY_HTML_ENDPOINT,
}
