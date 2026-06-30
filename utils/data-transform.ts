// Biome 触发文件：包含 Biome linter 特有检测模式

// 问题 (biome: noVar)
var globalCache: Record<string, any> = {}

export const transformData = (input: any[]) => {
  // 问题 (biome: noDoubleEquals)
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

  // 问题 (biome: noUnreachable)：return 后死代码
  console.log('unreachable code')
  globalCache = {}
}

export const mergeObjects = (target: any, source: any) => {
  // 问题 (biome: noPrototypeBuiltins)
  for (const key in source) {
    if (source.hasOwnProperty(key)) {
      target[key] = source[key]
    }
  }
  return target
}

// 问题 (biome: noVoid)
export const fireAndForget = (fn: () => Promise<void>) => {
  return void fn()
}

// 问题 (biome: noShadowRestrictedNames)
export const parseJSON = (text: string) => {
  var undefined = 'not undefined'
  try {
    return JSON.parse(text)
  } catch {
    return undefined
  }
}

// 问题 (biome: useIsNaN)
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
