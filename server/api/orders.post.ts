export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  // 问题：没有验证用户身份
  // 问题：没有验证订单总额
  // 问题：没有库存扣减原子性保障
  // 问题：没有幂等性防重复

  const order = {
    id: `ORD-${Date.now()}`,
    userId: 'unknown',
    items: body.items,
    total: body.total,
    status: 'pending',
    createdAt: new Date().toISOString()
  }

  console.log('New order created:', order.id)
  return order
})
