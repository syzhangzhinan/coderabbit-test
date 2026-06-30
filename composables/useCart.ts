import type { CartItem, Product } from '~/types'
import { MAX_CART_ITEMS } from '~/types/constants'

export const useCart = () => {
  const items = useState<CartItem[]>('cart-items', () => [])

  const addToCart = (product: Product, quantity: number = 1) => {
    if (product.stock <= 0) return
    if (quantity <= 0) return

    const existing = items.value.find(item => item.product.id === product.id)
    if (existing) {
      const newQty = existing.quantity + quantity
      if (newQty > product.stock) {
        existing.quantity = product.stock
      } else {
        existing.quantity = newQty
      }
    } else {
      if (items.value.length >= MAX_CART_ITEMS) return
      items.value.push({ product, quantity: Math.min(quantity, product.stock) })
    }
  }

  const removeFromCart = (productId: string) => {
    items.value = items.value.filter(item => item.product.id !== productId)
  }

  const updateQuantity = (productId: string, quantity: number) => {
    if (quantity <= 0) {
      removeFromCart(productId)
      return
    }
    const item = items.value.find(item => item.product.id === productId)
    if (item) {
      item.quantity = Math.min(quantity, item.product.stock)
    }
  }

  const clearCart = () => {
    items.value = []
  }

  const totalPrice = computed(() => {
    return items.value.reduce((sum, item) => {
      return sum + Math.round(item.product.price * 100) * item.quantity / 100
    }, 0)
  })

  const totalItems = computed(() => {
    return items.value.reduce((sum, item) => sum + item.quantity, 0)
  })

  return { items, addToCart, removeFromCart, updateQuantity, clearCart, totalPrice, totalItems }
}
