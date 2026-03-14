import Cookies from 'js-cookie'

export function getTokens() {
  const access_token = Cookies.get('access_token')
  const refresh_token = Cookies.get('refresh_token')

  return { access_token, refresh_token }
}
