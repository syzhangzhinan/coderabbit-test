/**
 * 价格格式化工具
 *
 * 测试场景 3: 被 components/ProductCard.vue 和 pages/products/[id].vue 引用
 */
export function formatPrice(
  amount: number,
  // currency: string = "CNY",
  // 场景 3: 工具函数引用
  currency: string = "USD",
  locale: string = "zh-CN"
): string {
  return new Intl.NumberFormat(locale, {
    style: "currency",
    currency
  }).format(amount)
}

/**
 * 价格格式化工具
 *
 * 变更：
 *  - currency 不再有默认值，成为必需参数
 *  - locale 与 currency 的参数顺序互换，使业务方更直观地先指定展示区域再指定币种
 */
// export function formatPrice(amount: number, locale: string, currency: string): string {
//   return new Intl.NumberFormat(locale, {
//     style: "currency",
//     currency
//   }).format(amount)
// }

/**
 * 价格格式化工具
 *
 * 变更：
 *  - currency 不再有默认值，成为必需参数
 *  - locale 与 currency 的参数顺序互换
 */
// export function formatPrice(amount: number, locale: string, currency: string): string {
//   return new Intl.NumberFormat(locale, {
//     style: "currency",
//     currency
//   }).format(amount)
// }
