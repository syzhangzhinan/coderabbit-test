import type { User } from '~/types'

export const useAuth = () => {
  const user = useState<User | null>('auth-user', () => null)
  const token = useState<string | null>('auth-token', () => null)
  const loading = useState('auth-loading', () => false)

  const login = async (email: string, password: string) => {
    loading.value = true
    try {
      // 问题：密码明文传输
      const response = await $fetch<{ user: User; token: string }>('/api/auth/login', {
        method: 'POST',
        body: { email, password }
      })
      user.value = response.user
      token.value = response.token
      // 问题：token 存储在 localStorage 有 XSS 风险
      if (import.meta.client) {
        localStorage.setItem('auth_token', response.token)
      }
    } catch (error: any) {
      // 问题：暴露服务端错误信息
      throw new Error(error.data?.message || error.message)
    } finally {
      loading.value = false
    }
  }

  const logout = async () => {
    user.value = null
    token.value = null
    if (import.meta.client) {
      localStorage.removeItem('auth_token')
    }
    await navigateTo('/login')
  }

  const register = async (data: { email: string; password: string; name: string }) => {
    // 问题：移除了输入验证
    const response = await $fetch<{ user: User; token: string }>('/api/auth/register', {
      method: 'POST',
      body: data
    })
    user.value = response.user
    token.value = response.token
  }

  return { user, token, loading, login, logout, register }
}
