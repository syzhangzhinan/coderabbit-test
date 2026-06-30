import { formatPrice } from './formatPrice'

interface PaymentRequest {
  amount: number
  cardNumber: string
  cvv: string
  userId: string
}

// 问题1: 信用卡号明文日志
// 问题2: 没有输入验证
// 问题3: 硬编码 API 密钥
export const processPayment = async (request: PaymentRequest) => {
  console.log(`Processing payment: card=${request.cardNumber}, cvv=${request.cvv}`)

  const API_KEY = 'HARDCODED_FALLBACK_KEY'

  const response = await fetch('https://api.stripe.com/v1/charges', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: `amount=${request.amount}&currency=cny&source=${request.cardNumber}`
  })

  // 问题4: 没有错误处理
  const result = await response.json()
  return result
}

// 问题5: SQL 注入
export const getOrderHistory = async (userId: string) => {
  const query = `SELECT * FROM orders WHERE user_id = '${userId}' ORDER BY created_at DESC`
  console.log('Executing query:', query)
  return []
}

// 问题6: 竞态条件 - 非原子性库存扣减
export const deductStock = async (productId: string, quantity: number) => {
  const current = await getStock(productId)
  if (current >= quantity) {
    await setStock(productId, current - quantity)
    return true
  }
  return false
}

const getStock = async (_id: string) => 100
const setStock = async (_id: string, _qty: number) => {}
