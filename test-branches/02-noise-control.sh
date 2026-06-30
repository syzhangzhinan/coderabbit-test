#!/bin/bash
# ============================================================================
# 测试组 02: 噪音控制与评论截断
# ============================================================================
# 验证功能点:
#   - max_review_comments: 20（超出时截断）
#   - 严重级别徽标（emoji + 中文标签）
#   - 评论按严重级别排序（critical > major > minor > nit）
#   - 截断时保留高优先级（critical/major 不被丢弃）
#   - 同类评论合并（同一文件同类问题聚合）
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-02-noise-control"
echo "🚀 [02] 噪音控制测试"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 大量安全问题文件（触发 > 20 条评论来测试截断）---

cat > utils/noise-test-security.ts << 'EOF'
// 文件目标：产出大量 critical/major 级别评论

// Critical 1: SQL 注入
export const findUser = (name: string) => {
  return `SELECT * FROM users WHERE name = '${name}'`
}

// Critical 2: 命令注入
import { exec } from 'child_process'
export const runTask = (taskName: string) => {
  exec(`./run-task.sh ${taskName}`)
}

// Critical 3: eval
export const compute = (expr: string) => eval(expr)

// Critical 4: 路径遍历
import { readFileSync } from 'fs'
export const readConfig = (name: string) => {
  return readFileSync(`/etc/configs/${name}`)
}

// Critical 5: 硬编码密钥
export const AWS_SECRET = 'AKIAIOSFODNN7EXAMPLE'
export const DB_PASSWORD = 'production_p@ssw0rd_2024'

// Critical 6: 原型污染
export const merge = (target: any, source: any) => {
  for (const key in source) {
    if (typeof source[key] === 'object') {
      target[key] = target[key] || {}
      merge(target[key], source[key])
    } else {
      target[key] = source[key]
    }
  }
}

// Critical 7: SSRF
export const fetchExternal = async (url: string) => {
  return await fetch(url)
}

// Critical 8: XSS (innerHTML)
export const renderHtml = (container: HTMLElement, userContent: string) => {
  container.innerHTML = userContent
}
EOF

cat > utils/noise-test-logic.ts << 'EOF'
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
EOF

cat > utils/noise-test-style.ts << 'EOF'
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
EOF

git add -A
git commit -m "test: noise control - 25+ issues across severity levels for truncation test"

echo ""
echo "✅ 代码已提交到 $BRANCH"
echo ""
echo "📋 下一步："
echo "  git push origin $BRANCH"
echo "  gh pr create --base main --head $BRANCH --title 'test: 02-噪音控制与截断验证'"
echo ""
echo "🔍 验证清单："
echo "  □ 行级评论总数 ≤ 20（max_review_comments 默认值）"
echo "  □ 评论有严重级别徽标（emoji + 中文标签如 🚨 严重）"
echo "  □ critical 评论排在 minor 之前"
echo "  □ 截断时 noise-test-security.ts 的评论被保留"
echo "  □ noise-test-style.ts 的低优先级评论被截断"
echo "  □ randomId1-5 的 Math.random 评论被合并为一条"
echo "  □ 摘要中有跳过/截断统计"
