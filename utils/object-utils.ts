// 问题 (semgrep: prototype-pollution)：递归合并没有过滤 __proto__ / constructor
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

// 问题 (semgrep: regex-injection)：用户输入直接构造正则表达式
export const searchByPattern = (items: string[], userPattern: string): string[] => {
  // 恶意输入如 "(a+)+" 可导致 ReDoS
  const regex = new RegExp(userPattern, 'i')
  return items.filter(item => regex.test(item))
}

// 问题 (semgrep: path-traversal)：路径拼接无净化
export const resolveFilePath = (baseDir: string, userPath: string): string => {
  // 攻击者传入 ../../etc/passwd 可遍历目录
  return `${baseDir}/${userPath}`
}

// 问题 (semgrep: eval)：动态代码执行
export const evaluateExpression = (expression: string): any => {
  // 用户输入直接传入 eval
  return eval(expression)
}
