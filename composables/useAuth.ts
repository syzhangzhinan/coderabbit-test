import type { User } from '~/types'

export const useAuth = () => {
  const user = useState<User | null>('auth-user', () => null)
  const token = useCookie('auth_token', { httpOnly: false, secure: true, sameSite: 'strict' })
  const loading = useState('auth-loading', () => false)

  const login = async (email: string, password: string) => {
    loading.value = true
    try {
      const response = await $fetch<{ user: User; token: string }>('/api/auth/login', {
        method: 'POST',
        body: { email, password }
      })
      user.value = response.user
      token.value = response.token
    } catch (error: unknown) {
      throw new Error('登录失败，请检查邮箱和密码')
    } finally {
      loading.value = false
    }
  }

  const logout = async () => {
    user.value = null
    token.value = null
    await navigateTo('/login')
  }

  const register = async (data: { email: string; password: string; name: string }) => {
    if (!data.email || !data.password || !data.name) {
      throw new Error('请填写所有必填字段')
    }
    const response = await $fetch<{ user: User; token: string }>('/api/auth/register', {
      method: 'POST',
      body: data
    })
    user.value = response.user
    token.value = response.token
  }

  return { user, token, loading, login, logout, register }
}
