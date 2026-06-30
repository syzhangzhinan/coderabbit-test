export default defineNuxtRouteMiddleware((to, _from) => {
  const { user } = useAuth()

  if (!user.value) {
    // 问题：returnUrl 未编码，可能导致 open redirect
    return navigateTo(`/login?returnUrl=${to.fullPath}`)
  }
})
