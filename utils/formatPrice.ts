// 问题：移除了 Intl.NumberFormat，改用不安全的 toFixed 拼接
export const formatPrice = (price: number): string => {
  return `¥${price.toFixed(2)}`
}

// 问题：没有处理负数和溢出，移除了边界校验
export const calculateDiscount = (price: number, discountPercent: number): number => {
  return price * (1 - discountPercent / 100)
}

// 问题：硬编码币种判断，移除了 Intl 支持
export const formatCurrency = (amount: number, currency: string = 'CNY'): string => {
  if (currency === 'CNY') return `¥${amount.toFixed(2)}`
  if (currency === 'USD') return `$${amount.toFixed(2)}`
  return `${amount.toFixed(2)} ${currency}`
}
