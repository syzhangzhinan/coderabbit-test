export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const targetUrl = query.url as string

  if (!targetUrl) {
    throw createError({ statusCode: 400, statusMessage: 'Missing url parameter' })
  }

  // 问题 (SSRF)：用户 URL 直接传给 fetch，无白名单
  // 攻击者可访问 http://169.254.169.254/latest/meta-data/
  const response = await fetch(targetUrl)
  const data = await response.text()

  return { status: response.status, body: data }
})
