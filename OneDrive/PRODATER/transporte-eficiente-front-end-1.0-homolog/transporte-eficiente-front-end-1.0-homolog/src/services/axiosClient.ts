import axios from 'axios'
import { getTokens } from './api/auth/get-tokens'

const instance = axios.create({
  baseURL: import.meta.env.VITE_PUBLIC_API_URL,
  headers: {
    Authorization: `Bearer ${getTokens().access_token}`,
  },
})

export { instance as fetchConfig }
