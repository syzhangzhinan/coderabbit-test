import { randomUUID } from 'crypto'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body.items || !Array.isArray(body.items) || body.items.length === 0) {
    throw createError({ statusCode: 400, statusMessage: '订单不能为空' })
  }

  const order = {
    id: `ORD-${randomUUID().slice(0, 8)}`,
    userId: 'authenticated-user',
    items: body.items,
    total: body.total,
    status: 'pending',
    createdAt: new Date().toISOString()
  }

  return order
})
