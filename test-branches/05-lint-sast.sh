#!/bin/bash
# ============================================================================
# 测试组 05: Linter/SAST 集成
# ============================================================================
# 验证功能点:
#   - enable_lint_tools: true（总开关）
#   - enable_eslint: true + eslint_version
#   - enable_biome: true + biome_version
#   - enable_tsc: true + tsc_version
#   - enable_prettier: false（默认关闭）
#   - enable_semgrep: false（默认关闭，需手动开启测试）
#   - 工具归因卡片（🧰 Tools）
#   - 各工具版本配置
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-05-lint-sast"
echo "🚀 [05] Linter/SAST 集成测试"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- ESLint 专项测试文件 ---
cat > utils/eslint-violations.ts << 'EOF'
// ESLint 规则违反集合

// no-unused-vars
const unusedVariable = 'I am never used'

// no-constant-condition
export const alwaysTrue = () => {
  if (true) {
    return 'yes'
  }
  return 'no'
}

// no-async-promise-executor
export const badPromise = new Promise(async (resolve) => {
  const data = await fetch('/api/data')
  resolve(data)
})

// prefer-const
export const mutateNothing = () => {
  let x = 10
  return x + 1
}

// no-prototype-builtins
export const hasKey = (obj: any, key: string) => {
  return obj.hasOwnProperty(key)
}

// no-empty
export const silentCatch = () => {
  try {
    JSON.parse('invalid')
  } catch (e) {}
}

// eqeqeq
export const looseCompare = (a: any, b: any) => {
  return a == b
}

// no-var
export const useVar = () => {
  var result = 'hello'
  return result
}
EOF

# --- Biome 专项测试文件 ---
cat > utils/biome-violations.ts << 'EOF'
// Biome linter 规则违反集合

// noDoubleEquals
export const compare = (a: any, b: any) => a == b

// noVar
var biomeGlobal = 'should be const'

// useIsNaN
export const checkNan = (x: number) => x === NaN

// noShadowRestrictedNames
export const shadow = () => {
  var undefined = 42
  return undefined
}

// noPrototypeBuiltins
export const checkProto = (obj: any) => obj.hasOwnProperty('key')

// noUnreachable
export const dead = () => {
  return 1
  return 2
}

// noFallthroughSwitchClause
export const noBreak = (x: number) => {
  switch (x) {
    case 1:
      console.log('one')
    case 2:
      console.log('two')
      break
    default:
      console.log('other')
  }
}

// useExponentiationOperator
export const power = (base: number, exp: number) => Math.pow(base, exp)

// noVoid
export const voidUsage = () => void 0

export { biomeGlobal }
EOF

# --- TSC 专项测试文件 ---
cat > utils/tsc-errors.ts << 'EOF'
// TypeScript 编译错误集合（strict 模式下报错）

interface Config {
  host: string
  port: number
  ssl: boolean
}

// 类型不匹配
export const createConfig = (): Config => {
  return {
    host: 'localhost',
    port: '3000' as any,
    ssl: 'true' as any
  }
}

// 缺少属性
export const partialConfig = (): Config => {
  return { host: 'localhost' } as Config
}

// 不安全的类型断言
export const unsafeCast = (data: unknown) => {
  return (data as any).nested.property.value
}

// null 安全问题
export const maybeNull = (arr: string[] | null) => {
  return arr.length
}

// 参数类型错误
export const add = (a: number, b: number): number => a + b
export const callAdd = () => add('1' as any, '2' as any)
EOF

# --- Semgrep 专项测试文件（enable_semgrep: true 时生效）---
cat > utils/semgrep-vulnerabilities.ts << 'EOF'
// Semgrep SAST 检测目标（需要 enable_semgrep: true）

import { exec } from 'child_process'
import { readFileSync, writeFileSync } from 'fs'
import { createServer } from 'http'

// CWE-78: OS Command Injection
export const runCommand = (userInput: string) => {
  exec(`ls ${userInput}`, (err, stdout) => {
    console.log(stdout)
  })
}

// CWE-22: Path Traversal
export const readUserFile = (filename: string) => {
  const content = readFileSync(`/data/uploads/${filename}`, 'utf-8')
  return content
}

// CWE-918: SSRF
export const proxyRequest = async (targetUrl: string) => {
  const res = await fetch(targetUrl)
  return res.text()
}

// CWE-79: XSS via innerHTML
export const renderUserContent = (el: HTMLElement, content: string) => {
  el.innerHTML = content
}

// CWE-502: Deserialization
export const loadData = (serialized: string) => {
  return eval(`(${serialized})`)
}

// CWE-798: Hard-coded Credentials
const JWT_SECRET = 'super-secret-key-never-change'
export const signToken = (payload: any) => {
  return `${btoa(JSON.stringify(payload))}.${JWT_SECRET}`
}

// CWE-611: XXE (if using XML parser)
export const parseXml = (xmlString: string) => {
  const parser = new DOMParser()
  return parser.parseFromString(xmlString, 'text/xml')
}
EOF

git add -A
git commit -m "test: lint/SAST - ESLint + Biome + tsc + Semgrep violation files"

echo ""
echo "✅ 代码已提交到 $BRANCH"
echo ""
echo "📋 下一步："
echo "  git push origin $BRANCH"
echo "  gh pr create --base main --head $BRANCH --title 'test: 05-Linter/SAST集成验证'"
echo ""
echo "🔍 验证清单："
echo "  □ ESLint 检测结果注入到 AI 评论中（引用规则名）"
echo "  □ Biome 检测结果注入到 AI 评论中（引用规则名）"
echo "  □ tsc 类型错误注入到 AI 评论中（引用 TS 错误码）"
echo "  □ 评论底部有 🧰 Tools 归因卡片"
echo "  □ 归因卡片列出触发的工具（ESLint/Biome/tsc）"
echo "  □ [可选] 开启 enable_semgrep: true 后 Semgrep 检测生效"
echo "  □ [可选] enable_lint_tools: false 时无任何 lint 内容"
