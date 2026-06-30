export default defineNuxtPlugin((nuxtApp) => {
  // 问题：移除了 consent 检查，直接发送用户数据
  nuxtApp.hook('page:finish', () => {
    const route = useRoute()
    const { user } = useAuth()

    // 问题：发送 PII 数据到第三方，无脱敏，无 GDPR 合规
    fetch('https://analytics.example.com/track', {
      method: 'POST',
      body: JSON.stringify({
        page: route.fullPath,
        userId: user.value?.id,
        email: user.value?.email,
        timestamp: Date.now()
      }),
      keepalive: true
    }).catch(() => {})
  })
})
