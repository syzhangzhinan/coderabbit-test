export default defineNuxtPlugin((nuxtApp) => {
  nuxtApp.vueApp.config.errorHandler = (error, instance, info) => {
    if (import.meta.dev) {
      console.error('Global error:', error, '\nComponent:', instance, '\nInfo:', info)
    }
    // Production: send to monitoring service
  }

  nuxtApp.hook('vue:error', (error, instance, info) => {
    if (import.meta.dev) {
      console.error('Vue error:', error, '\nComponent:', instance, '\nInfo:', info)
    }
  })
})
