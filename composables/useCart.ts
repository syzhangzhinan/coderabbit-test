/**
 * 购物车 composable
 *
 * 测试场景 2: 被 pages/cart.vue 和 components/CartSummary.vue 通过 Nuxt auto-import 使用
 */

export interface CartItem {
  id: string
  name: string
  price: number
  quantity: number
}

export function useCart() {
  const items = useState<CartItem[]>("cart-items", () => [])

  const total = computed(() =>
    items.value.reduce((sum, item) => sum + item.price * item.quantity, 0)
  )

  function addItem(item: Omit<CartItem, "quantity">) {
    const existing = items.value.find((i) => i.id === item.id)
    if (existing) {
      existing.quantity++
    } else {
      items.value.push({ ...item, quantity: 1 })
    }
  }

  function removeItem(id: string) {
    items.value = items.value.filter((i) => i.id !== id)
  }

  // 场景 2: Composable Auto-Import (Nuxt 约定)
  // function removeItem(id: string, silent: boolean = false) {
  //   items.value = items.value.filter((i) => i.id !== id)
  //   if (!silent) console.log(`Removed item: ${id}`)
  // }

  return { items, total, addItem, removeItem }
}
