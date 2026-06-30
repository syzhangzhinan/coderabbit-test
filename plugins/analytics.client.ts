export default defineNuxtPlugin((nuxtApp) => {
  const consentGiven = useCookie('analytics_consent')

  nuxtApp.hook('page:finish', () => {
    if (!consentGiven.value) return

    const route = useRoute()

    fetch('/api/analytics/track', {
      method: 'POST',
      body: JSON.stringify({
        page: route.path,
        timestamp: Date.now()
      }),
      keepalive: true
    }).catch(() => {})
  })
})
