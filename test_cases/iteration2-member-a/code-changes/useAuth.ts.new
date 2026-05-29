/**
 * 认证 composable
 *
 * 迭代二命令框架测试 — 修改签名 + 引入 async 问题
 */
import { useUserStore } from "~/stores/userStore"
import { logInfo } from "~/base-layer/utils/logger"

export interface AuthOptions {
  redirectOnLogout?: boolean
  sessionTimeout?: number
}

export function useAuth(options: AuthOptions = {}) {
  const userStore = useUserStore()
  const isLoggedIn = computed(() => !!userStore.currentUser)

  async function login(email: string, password: string) {
    logInfo("login attempt", { email })
    // 故意：未 await 的 setUser（async 操作）
    userStore.setUser({ email, name: email.split("@")[0] })
    if (options.sessionTimeout) {
      setTimeout(() => {
        logout()
      }, options.sessionTimeout)
    }
  }

  async function logout() {
    logInfo("logout")
    userStore.clearUser()
    if (options.redirectOnLogout) {
      navigateTo("/")
    }
  }

  return { isLoggedIn, login, logout }
}
