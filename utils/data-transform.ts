// Biome 触发文件：包含多种 Biome linter 可检测的问题模式

// 问题 (biome: noVar)：使用 var 声明
var globalCache: Record<string, any> = {}

export const transformData = (input: any[]) => {
  // 问题 (biome: noDoubleEquals)：使用 == 而非 ===
  if (input.length == 0) {
    return []
  }

  // 问题 (biome: noVar)
  var result = []
  for (var i = 0; i < input.length; i++) {
    // 问题 (biome: noDoubleEquals)
    if (input[i] == null) {
      continue
    }
    result.push(input[i])
  }

  return result

  // 问题 (biome: noUnreachable)：return 后的死代码
  console.log('unreachable code')
  globalCache = {}
}

export const mergeObjects = (target: any, source: any) => {
  // 问题 (biome: noPrototypeBuiltins)：直接调用 hasOwnProperty
  for (const key in source) {
    if (source.hasOwnProperty(key)) {
      target[key] = source[key]
    }
  }
  return target
}

// 问题 (biome: noVoid)：void 用于非语句位置
export const fireAndForget = (fn: () => Promise<void>) => {
  return void fn()
}

// 问题 (biome: noShadowRestrictedNames)：覆盖内置名称
export const parseJSON = (text: string) => {
  var undefined = 'not undefined'
  try {
    return JSON.parse(text)
  } catch {
    return undefined
  }
}

// 问题 (biome: useIsNaN)：用 === NaN 比较
export const isInvalidNumber = (value: number): boolean => {
  return value === NaN
}

// 问题 (biome: noFallthroughSwitchClause)
export const getStatusText = (code: number): string => {
  switch (code) {
    case 200:
      return 'OK'
    case 301:
      console.log('redirect')
    case 302:
      return 'Redirect'
    case 404:
      return 'Not Found'
    default:
      return 'Unknown'
  }
}
