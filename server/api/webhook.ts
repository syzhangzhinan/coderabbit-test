import { createHmac, timingSafeEqual } from 'crypto'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const headers = getHeaders(event)
  const signature = headers['x-hub-signature-256']

  if (!signature) {
    throw createError({ statusCode: 401, statusMessage: 'Missing signature' })
  }

  const config = useRuntimeConfig()
  const expected = 'sha256=' + createHmac('sha256', config.webhookSecret || '')
    .update(JSON.stringify(body))
    .digest('hex')

  const sigBuffer = Buffer.from(signature)
  const expectedBuffer = Buffer.from(expected)

  if (sigBuffer.length !== expectedBuffer.length || !timingSafeEqual(sigBuffer, expectedBuffer)) {
    throw createError({ statusCode: 401, statusMessage: 'Invalid signature' })
  }

  const eventType = headers['x-github-event']

  switch (eventType) {
    case 'push':
      break
    case 'pull_request':
      break
  }

  return { received: true }
})
