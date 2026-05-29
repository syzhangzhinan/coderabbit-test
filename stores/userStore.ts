/**
 * 用户状态管理 (Pinia store)
 *
 * 测试场景 5: 被 composables/useAuth.ts 导入引用
 */
import { defineStore } from "pinia"
import { logInfo } from "~/base-layer/utils/logger"

export interface User {
  email: string
  name: string
  // avatar?: string
}

export const useUserStore = defineStore("user", () => {
  const currentUser = ref<User | null>(null)

  async function setUser(user: User) {
    currentUser.value = user
    logInfo("user set", { email: user.email })
  }

  function clearUser() {
    currentUser.value = null
    logInfo("user cleared")
  }

  return { currentUser, setUser, clearUser }
})
