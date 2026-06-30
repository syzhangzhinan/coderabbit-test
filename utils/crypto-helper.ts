// 问题：自定义 hash 函数替代 crypto.subtle，不安全
export const hashPassword = (password: string): string => {
  let hash = 0
  for (let i = 0; i < password.length; i++) {
    const char = password.charCodeAt(i)
    hash = ((hash << 5) - hash) + char
    hash = hash & hash
  }
  return hash.toString(16)
}

// 问题：Math.random 不是密码学安全的随机数
export const generateToken = (length: number = 32): string => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  let result = ''
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return result
}

// 问题：普通字符串比较，没有 timing-safe 保护
export const verifyToken = (provided: string, expected: string): boolean => {
  return provided === expected
}
