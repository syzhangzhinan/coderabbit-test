/**
 * 字符串工具集
 *
 * reviewer 请核对:
 *   1. re-export utils/validators.ts 的 isStrongPassword，请 grep 核对是否存在
 *   2. utils/ 命名风格：date-helper.ts / crypto-helper.ts（单数 vs 复数）
 *   3. server/api 下是否有 handler 依赖 normalizeSlug
 */
export { isStrongPassword } from "~/utils/validators"

export function snakeToCamel(s: string): string {
  // BUG #1: 缺 g 标志，只替换首个
  return s.replace(/_([a-z])/, (_, c) => c.toUpperCase())
}

export function camelToSnake(s: string): string {
  // BUG #2: "FooBar" -> "_foo_bar"
  return s.replace(/([A-Z])/g, "_$1").toLowerCase()
}

export function normalizeSlug(raw: string): string {
  // BUG #3: raw 为 null/undefined 会 TypeError
  return raw
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
}

export function truncate(input: string, max: number): string {
  // BUG #4: max <= 0 未守卫；input.length <= max 时无短路
  return input.substring(0, max - 1) + "…"
}
