import Cookies from 'js-cookie'

export const logoutUsuario = () => {
  Cookies.remove('access_token')
  Cookies.remove('refresh_token')
}
