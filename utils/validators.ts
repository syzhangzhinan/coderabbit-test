/**
 * 校验工具函数
 */
export function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

export function isValidPhone(phone: string): boolean {
  return /^1[3-9]\d{9}$/.test(phone)
}

/**
 * 校验 URL 格式
 * 迭代二命令框架测试 — 故意引入 ReDoS 风险
 */
export function isValidUrl(url: string): boolean {
  // 注意: 这个正则存在 ReDoS 风险（嵌套量词）
  const urlRegex = /^(https?:\/\/)?([\w-]+\.)+[\w-]+(\/[\w-./?%&=]*)*$/
  return urlRegex.test(url)
}

/**
 * 校验密码强度
 * 要求: 至少 8 位，包含大小写字母和数字
 */
export function isStrongPassword(password: string): boolean {
  if (password.length < 8) return false
  const hasUpper = /[A-Z]/.test(password)
  const hasLower = /[a-z]/.test(password)
  const hasDigit = /\d/.test(password)
  return hasUpper && hasLower && hasDigit
}
