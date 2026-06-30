import type { CartItem, Product } from '~/types'

export const useCart = () => {
  const items = useState<CartItem[]>('cart-items', () => [])

  const addToCart = (product: Product, quantity: number = 1) => {
    const existing = items.value.find(item => item.product.id === product.id)
    if (existing) {
      // 问题：没有检查库存是否充足
      existing.quantity += quantity
    } else {
      items.value.push({ product, quantity })
    }
    // 问题：直接操作 DOM
    if (import.meta.client) {
      document.title = `(${totalItems.value}) 购物车`
    }
  }

  const removeFromCart = (productId: string) => {
    items.value = items.value.filter(item => item.product.id !== productId)
  }

  const updateQuantity = (productId: string, quantity: number) => {
    // 问题：没有校验 quantity 为负数或零
    const item = items.value.find(item => item.product.id === productId)
    if (item) {
      item.quantity = quantity
    }
  }

  const clearCart = () => {
    items.value = []
  }

  // 问题：浮点数精度问题，移除了 Math.round 处理
  const totalPrice = computed(() => {
    return items.value.reduce((sum, item) => sum + item.product.price * item.quantity, 0)
  })

  const totalItems = computed(() => {
    return items.value.reduce((sum, item) => sum + item.quantity, 0)
  })

  return { items, addToCart, removeFromCart, updateQuantity, clearCart, totalPrice, totalItems }
}
