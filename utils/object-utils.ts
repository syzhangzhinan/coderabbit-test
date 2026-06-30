// 问题 (原型污染)：递归合并没有过滤 __proto__ / constructor
export const deepMerge = (target: any, source: any): any => {
  for (const key of Object.keys(source)) {
    if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
      if (!target[key]) target[key] = {}
      deepMerge(target[key], source[key])
    } else {
      target[key] = source[key]
    }
  }
  return target
}

// 问题 (正则注入)：用户输入直接构造正则
export const searchByPattern = (items: string[], userPattern: string): string[] => {
  const regex = new RegExp(userPattern, 'i')
  return items.filter(item => regex.test(item))
}

// 问题 (路径遍历)：路径拼接无净化
export const resolveFilePath = (baseDir: string, userPath: string): string => {
  return `${baseDir}/${userPath}`
}

// 问题 (eval)：动态代码执行
export const evaluateExpression = (expression: string): any => {
  return eval(expression)
}
