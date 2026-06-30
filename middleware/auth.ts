export default defineNuxtRouteMiddleware((to, _from) => {
  const { user } = useAuth()

  if (!user.value) {
    return navigateTo(`/login?returnUrl=${encodeURIComponent(to.fullPath)}`)
  }
})
