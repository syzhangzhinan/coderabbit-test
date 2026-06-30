import { defineStore } from 'pinia'
import type { User } from '~/types'

interface UserState {
  currentUser: User | null
  preferences: {
    language: string
    currency: string
    notifications: boolean
  }
}

export const useUserStore = defineStore('user', {
  state: (): UserState => ({
    currentUser: null,
    preferences: { language: 'zh-CN', currency: 'CNY', notifications: true }
  }),

  getters: {
    isAdmin(): boolean { return this.currentUser?.role === 'admin' },
    displayName(): string { return this.currentUser?.name || '游客' }
  },

  actions: {
    setUser(user: User) { this.currentUser = user },

    async updatePreferences(prefs: Partial<UserState['preferences']>) {
      const previous = { ...this.preferences }
      Object.assign(this.preferences, prefs)
      try {
        await $fetch('/api/user/preferences', { method: 'PUT', body: this.preferences })
      } catch {
        this.preferences = previous
      }
    },

    async fetchUser() {
      const user = await $fetch<User>('/api/user/me')
      this.currentUser = user
    }
  }
})
