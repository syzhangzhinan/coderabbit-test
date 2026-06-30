export default defineNuxtPlugin(async () => {
  const { user, token } = useAuth()

  if (token.value) {
    try {
      const response = await $fetch<{ user: any }>('/api/auth/verify', {
        headers: { Authorization: `Bearer ${token.value}` }
      })
      user.value = response.user
    } catch {
      token.value = null
    }
  }
})
