export default defineNuxtRouteMiddleware((to, _from) => {
  const { user } = useAuth()
  const publicRoutes = ['/', '/login', '/register', '/products']

  if (!publicRoutes.includes(to.path) && !user.value) {
    return navigateTo('/login')
  }
})
