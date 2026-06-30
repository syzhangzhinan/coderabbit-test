export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const headers = getHeaders(event)

  // 问题：webhook 签名验证完全移除
  const eventType = headers['x-github-event']

  switch (eventType) {
    case 'push':
      console.log('Push event received:', body.ref)
      break
    case 'pull_request':
      console.log('PR event:', body.action, body.pull_request?.title)
      break
    default:
      console.log('Unknown event type:', eventType)
  }

  return { received: true }
})
