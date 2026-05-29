/**
 * 日志工具（来自 base-layer）
 *
 * 测试场景 8: 被 composables/useAuth.ts 和 stores/userStore.ts 显式导入
 */
export function logInfo(message: string, context?: Record<string, unknown>): void {
  const timestamp = new Date().toISOString()
  const contextStr = context ? ` ${JSON.stringify(context)}` : ""
  console.log(`[INFO] ${timestamp} ${message}${contextStr}`)
}

// export function logInfo(message: string, context?: Record<string, unknown>, tags?: string[]): void {
//   const timestamp = new Date().toISOString()
//   const contextStr = context ? ` ${JSON.stringify(context)}` : ""
//   const tagStr = tags?.length ? ` [${tags.join(",")}]` : ""
//   console.log(`[INFO] ${timestamp}${tagStr} ${message}${contextStr}`)
// }

export function logError(message: string, error?: Error): void {
  const timestamp = new Date().toISOString()
  console.error(`[ERROR] ${timestamp} ${message}`, error?.stack ?? "")
}

export function logWarn(message: string): void {
  const timestamp = new Date().toISOString()
  console.warn(`[WARN] ${timestamp} ${message}`)
}
