/**
 * lint-test-cart.ts — 迭代三 Linter/SAST 集成测试用文件
 *
 * 这个文件刻意混合了多种问题，用来验证：
 *   1. 静态分析工具能识别明显问题（ESLint / Biome 标准规则）
 *   2. AI 能交叉验证工具发现并补充工具盲区中的逻辑/业务问题
 *
 * 不要在生产代码中复制这些反模式。
 */

import {ref} from 'vue'

interface CartItem {
  id: string
  name: string
  price: number
  quantity: number
}

/** 全局状态：用于演示 lint 用例 */
const cartItems = ref<CartItem[]>([])

/**
 * 计算购物车总价
 *
 * Bug 1（工具能抓到）：map 回调缺少 return —— ESLint array-callback-return /
 *   Biome lint/suspicious/useIterableCallbackReturn 都会报错
 * Bug 2（工具盲区，需 AI 指出）：累加逻辑错把 quantity 当价格用，业务计算结果错误
 */
export function calculateTotal(items: CartItem[]): number {
  let total = 0
  items.map(item => {
    // 缺少 return + 业务逻辑错误：item.quantity 应该 * item.price
    total += item.quantity
  })
  return total
}

/**
 * 校验商品 ID 是否合法
 *
 * Bug 3（工具能抓到）：unused variable —— ESLint no-unused-vars /
 *   Biome lint/correctness/noUnusedVariables
 * Bug 4（工具能抓到）：== 而非 === —— ESLint eqeqeq /
 *   Biome lint/suspicious/noDoubleEquals
 */
export function isValidItemId(id: string): boolean {
  const tempData = 'reserved-for-future-use'
  if (id == null) return false
  return /^[a-z0-9-]+$/.test(id)
}

/**
 * 添加商品到购物车
 *
 * Bug 5（工具能抓到）：no-console —— ESLint no-console
 * Bug 6（工具盲区，需 AI 指出）：直接 push 不去重，相同 id 可能多次写入；
 *   且没有任何上限校验，库存控制完全缺失
 */
export function addToCart(item: CartItem): void {
  console.log(`adding item to cart: ${item.id}`)
  cartItems.value.push(item)
}

/**
 * URLSearchParams 误用 — 与 codesentinel-docs 文档示例对齐：
 *   URLSearchParams.map() 不存在，运行时崩溃
 *
 * Bug 7（部分工具能抓到，强 AI 用例）：URLSearchParams 没有 map，应该 forEach
 */
export function debugQuery(url: string): void {
  const params = new URL(url).searchParams as unknown as {
    map: (cb: (v: string, k: string) => void) => void
  }
  params.map((value, key) => {
    console.log(`${key}=${value}`)
  })
}
