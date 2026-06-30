export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const targetUrl = query.url as string

  if (!targetUrl) {
    throw createError({ statusCode: 400, statusMessage: 'Missing url parameter' })
  }

  // 问题 (semgrep: ssrf)：用户提供的 URL 直接传给 fetch，无白名单校验
  // 攻击者可传入内网地址如 http://169.254.169.254/latest/meta-data/
  const response = await fetch(targetUrl)
  const data = await response.text()

  return { status: response.status, body: data }
})
