import { defineStore } from 'pinia'
import type { IUser } from '@/types/models/IUser'

export const useUserStore = defineStore('user', {
  state: () => ({
    user: null as IUser | null,
  }),
  actions: {
    setUser(user: IUser | null) {
      this.user = user
    },
  },
})
