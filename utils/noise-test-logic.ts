// 文件目标：产出大量 major 级别评论（逻辑/性能问题）

// Major 1: 竞态条件
let counter = 0
export const increment = async () => {
  const current = counter
  await new Promise(r => setTimeout(r, 10))
  counter = current + 1
}

// Major 2: 内存泄漏
const cache = new Map<string, any>()
export const cacheData = (key: string, value: any) => {
  cache.set(key, value)
  // 永不清理
}

// Major 3: 无限循环风险
export const retry = async (fn: () => Promise<any>) => {
  while (true) {
    try {
      return await fn()
    } catch {
      // 无退出条件，无延迟
    }
  }
}

// Major 4: 浮点数精度
export const calculateTotal = (prices: number[]) => {
  return prices.reduce((a, b) => a + b, 0)
}

// Major 5: 时区问题
export const isExpired = (dateStr: string) => {
  return new Date(dateStr) < new Date()
}

// Major 6: 深拷贝问题
export const clone = (obj: any) => JSON.parse(JSON.stringify(obj))

// Major 7: Promise 未处理
export const fireAndForget = (url: string) => {
  fetch(url)
}

// Major 8: 数组越界
export const getFirst = (arr: any[]) => arr[0].name

// Major 9: 正则 ReDoS
export const validateEmail = (email: string) => {
  return /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/.test(email)
}

// Major 10: 大 O 复杂度
export const findDuplicates = (arr: number[]) => {
  const result: number[] = []
  for (let i = 0; i < arr.length; i++) {
    for (let j = i + 1; j < arr.length; j++) {
      if (arr[i] === arr[j] && !result.includes(arr[i])) {
        result.push(arr[i])
      }
    }
  }
  return result
}
