export default defineNuxtRouteMiddleware((_to, _from) => {
  const { user } = useAuth()

  if (!user.value) {
    return navigateTo('/login')
  }

  if (user.value.role !== 'admin') {
    return abortNavigation()
  }
})
