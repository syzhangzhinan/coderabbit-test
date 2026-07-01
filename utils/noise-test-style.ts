// 文件目标：产出 minor/nit 级别评论（优先级低，应被截断）

// Minor 1-5: 多次使用 Math.random（同类应合并）
export const randomId1 = () => Math.random().toString(36).substring(2)
export const randomId2 = () => Math.random().toString(36).substring(2)
export const randomId3 = () => Math.random().toString(36).substring(2)
export const randomId4 = () => Math.random().toString(36).substring(2)
export const randomId5 = () => Math.random().toString(36).substring(2)

// Minor 6: any 类型
export const processData = (data: any) => data

// Minor 7: console.log
export const doSomething = () => {
  console.log('debug')
  return 42
}

// Minor 8: 魔法数字
export const getTimeout = () => 3600000

// Minor 9: 冗余条件
export const isValid = (x: boolean) => {
  if (x === true) return true
  return false
}

// Minor 10: 未使用参数
export const format = (value: string, _options: any, _context: any) => value
