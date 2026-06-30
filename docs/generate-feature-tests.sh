#!/bin/bash
# ============================================================================
# AI Reviewer 全功能点测试代码生成脚本
# ============================================================================
# 根据 action.yml 定义的所有 inputs 功能点，生成对应的测试代码。
# 每个功能点对应一组测试文件，通过创建不同 PR 分支来验证各功能。
#
# 使用方式：
#   chmod +x docs/generate-feature-tests.sh
#   ./docs/generate-feature-tests.sh
#
# 脚本会生成多个分支脚本，你可以选择性执行：
#   ./test-branches/01-core-review.sh        # 核心审查流程
#   ./test-branches/02-noise-control.sh      # 噪音控制与截断
#   ./test-branches/03-path-filters.sh       # 路径过滤
#   ./test-branches/04-dependency.sh         # 跨文件依赖分析
#   ./test-branches/05-lint-sast.sh          # Linter/SAST 集成
#   ./test-branches/06-ai-tools.sh           # Web搜索与Shell
#   ./test-branches/07-commands.sh           # 命令系统
#   ./test-branches/08-conversation.sh       # 对话追问
#   ./test-branches/09-incremental.sh        # 增量审查
#   ./test-branches/10-i18n-identity.sh      # 国际化与Bot身份
#   ./test-branches/11-model-config.sh       # 模型配置
#
# 每个脚本会：
#   1. 从 main 创建 feature 分支
#   2. 生成对应的测试代码
#   3. 提交并创建 PR
#   4. 输出验证清单
# ============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH_DIR="$PROJECT_DIR/test-branches"

echo "============================================================"
echo " AI Reviewer 全功能点测试脚本生成器"
echo "============================================================"
echo ""
echo "📁 项目目录: $PROJECT_DIR"
echo "📁 输出目录: $BRANCH_DIR"
echo ""

mkdir -p "$BRANCH_DIR"

# ============================================================================
# 01 - 核心审查流程
# 测试功能: 自动审查触发、PR摘要、行级评论、Release Notes、disable_review、
#           disable_release_notes、review_simple_changes、review_comment_lgtm
# ============================================================================

cat > "$BRANCH_DIR/01-core-review.sh" << 'SCRIPT'
#!/bin/bash
# ============================================================================
# 测试组 01: 核心审查流程
# ============================================================================
# 验证功能点:
#   - PR 自动审查触发（新建 PR 时 Bot 自动产出审查）
#   - PR 摘要评论格式（Walkthrough + Changes 表格）
#   - 行级评论定位准确
#   - Release Notes 生成（PR 描述末尾 "Summary by CodeSentinel"）
#   - disable_review: true（仅摘要无行级评论）
#   - disable_release_notes: true（不生成 Release Notes）
#   - review_simple_changes: false（trivial 变更被 triage 跳过）
#   - review_comment_lgtm: false（无问题时不留评论）
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-01-core-review"
echo "🚀 [01] 核心审查流程测试"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 测试文件 1: 包含明显问题的代码（触发行级评论）---
cat > utils/payment-processor.ts << 'EOF'
import { formatPrice } from './formatPrice'

interface PaymentRequest {
  amount: number
  cardNumber: string
  cvv: string
  userId: string
}

// 问题1: 信用卡号明文日志
// 问题2: 没有输入验证
// 问题3: 硬编码 API 密钥
export const processPayment = async (request: PaymentRequest) => {
  console.log(`Processing payment: card=${request.cardNumber}, cvv=${request.cvv}`)

  const API_KEY = process.env.STRIPE_KEY || 'HARDCODED_FALLBACK_KEY'

  const response = await fetch('https://api.stripe.com/v1/charges', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: `amount=${request.amount}&currency=cny&source=${request.cardNumber}`
  })

  // 问题4: 没有错误处理
  const result = await response.json()
  return result
}

// 问题5: SQL 注入
export const getOrderHistory = async (userId: string) => {
  const query = `SELECT * FROM orders WHERE user_id = '${userId}' ORDER BY created_at DESC`
  console.log('Executing query:', query)
  return []
}

// 问题6: 竞态条件 - 非原子性库存扣减
export const deductStock = async (productId: string, quantity: number) => {
  const current = await getStock(productId)
  if (current >= quantity) {
    await setStock(productId, current - quantity)
    return true
  }
  return false
}

const getStock = async (_id: string) => 100
const setStock = async (_id: string, _qty: number) => {}
EOF

# --- 测试文件 2: 完全正确的代码（验证 review_comment_lgtm: false 时不留评论）---
cat > utils/string-helpers.ts << 'EOF'
export const capitalize = (str: string): string => {
  if (!str) return ''
  return str.charAt(0).toUpperCase() + str.slice(1)
}

export const truncate = (str: string, maxLength: number): string => {
  if (str.length <= maxLength) return str
  return str.slice(0, maxLength - 3) + '...'
}

export const slugify = (str: string): string => {
  return str
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '')
}
EOF

# --- 测试文件 3: trivial 变更（验证 review_simple_changes: false 被跳过）---
cat > types/constants.ts << 'EOF'
export const APP_NAME = 'AI Reviewer Test Store'
export const APP_VERSION = '1.2.0'
export const DEFAULT_PAGE_SIZE = 20
export const MAX_CART_ITEMS = 99
export const SUPPORTED_LANGUAGES = ['zh-CN', 'en-US', 'ja-JP']
export const ORDER_STATUS = ['pending', 'paid', 'shipped', 'completed'] as const
EOF

git add -A
git commit -m "test: core review - security issues + trivial changes + clean code"

echo ""
echo "✅ 代码已提交到 $BRANCH"
echo ""
echo "📋 下一步："
echo "  git push origin $BRANCH"
echo "  gh pr create --base main --head $BRANCH --title 'test: 01-核心审查流程验证'"
echo ""
echo "🔍 验证清单："
echo "  □ Bot 自动产出 PR 摘要评论"
echo "  □ 摘要含 Walkthrough（高级概述）+ Changes（文件变更表格）"
echo "  □ payment-processor.ts 产出行级评论（安全/逻辑问题）"
echo "  □ 行级评论定位到正确代码行"
echo "  □ PR 描述末尾有 Release Notes（Summary by CodeSentinel）"
echo "  □ string-helpers.ts 无行级评论（review_comment_lgtm: false）"
echo "  □ types/constants.ts 被 triage 为 APPROVED（review_simple_changes: false）"
SCRIPT

# ============================================================================
# 02 - 噪音控制
# 测试功能: max_review_comments、严重级别排序、同类合并、截断保留高优先级
# ============================================================================

cat > "$BRANCH_DIR/02-noise-control.sh" << 'SCRIPT'
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
SCRIPT

# ============================================================================
# 03 - 路径过滤
# 测试功能: path_filters 白/黑名单、默认排除规则
# ============================================================================

cat > "$BRANCH_DIR/03-path-filters.sh" << 'SCRIPT'
#!/bin/bash
# ============================================================================
# 测试组 03: 路径过滤 (path_filters)
# ============================================================================
# 验证功能点:
#   - 默认 path_filters 排除二进制/配置文件
#   - .lock / .json / .yaml / .yml 不审查
#   - .png / .zip 等二进制不审查
#   - dist/** 目录排除
#   - generated/** 目录排除
#   - max_files 限制（超出文件数时跳过统计）
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-03-path-filters"
echo "🚀 [03] 路径过滤测试"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 应被排除的文件（默认 path_filters）---

mkdir -p dist generated vendor

# 二进制/资产文件（应被跳过）
echo '{"name":"test","version":"1.0.0"}' > package-lock.json
echo 'lockfile content' > pnpm-lock-test.yaml
echo '# generated' > dist/index.js
echo '# generated' > generated/api-types.ts
echo '# vendor' > vendor/lodash.min.js

# 创建假的二进制文件
dd if=/dev/zero of=assets/test-image.png bs=1024 count=1 2>/dev/null
dd if=/dev/zero of=assets/test-archive.zip bs=1024 count=1 2>/dev/null

# 配置文件（默认被排除）
cat > test-config.yaml << 'EOF'
database:
  host: localhost
  password: insecure_password_in_yaml
EOF

cat > test-config.json << 'EOF'
{
  "apiKey": "sk-should-not-be-reviewed",
  "secret": "exposed-in-json"
}
EOF

# --- 应被审查的文件 ---

cat > utils/filter-test-reviewed.ts << 'EOF'
// 这个文件应该被正常审查
// 问题：SQL 注入（确认此文件被审查了）
export const query = (input: string) => `SELECT * FROM t WHERE x='${input}'`

// 问题：eval
export const run = (code: string) => eval(code)
EOF

git add -A
git commit -m "test: path filters - binary/config/generated files + reviewable .ts"

echo ""
echo "✅ 代码已提交到 $BRANCH"
echo ""
echo "📋 下一步："
echo "  git push origin $BRANCH"
echo "  gh pr create --base main --head $BRANCH --title 'test: 03-路径过滤验证'"
echo ""
echo "🔍 验证清单："
echo "  □ package-lock.json 不被审查"
echo "  □ .yaml/.json 配置文件不被审查"
echo "  □ dist/index.js 不被审查"
echo "  □ generated/api-types.ts 不被审查"
echo "  □ vendor/lodash.min.js 不被审查"
echo "  □ assets/test-image.png 不被审查"
echo "  □ assets/test-archive.zip 不被审查"
echo "  □ utils/filter-test-reviewed.ts 被正常审查并产出评论"
echo "  □ PR 摘要中有被跳过文件的统计"
SCRIPT

# ============================================================================
# 04 - 跨文件依赖分析
# 测试功能: enable_dependency_analysis、max_dependency_files
# ============================================================================

cat > "$BRANCH_DIR/04-dependency.sh" << 'SCRIPT'
#!/bin/bash
# ============================================================================
# 测试组 04: 跨文件依赖分析
# ============================================================================
# 验证功能点:
#   - enable_dependency_analysis: true（默认开启）
#   - 修改导出函数 → 审查评论提及引用方文件
#   - TypeScript import 解析
#   - Vue/Nuxt composable 引用跟踪
#   - max_dependency_files 限制
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-04-dependency"
echo "🚀 [04] 跨文件依赖分析测试"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 修改被多处引用的导出函数 ---

# 核心工具函数：修改签名（破坏性变更）
cat > utils/formatPrice.ts << 'EOF'
// 破坏性变更：移除了第二个参数 locale，引用方会受影响
export const formatPrice = (price: number): string => {
  return `¥${price.toFixed(2)}`
}

// 新增函数：修改返回类型从 number 改为 string
export const calculateDiscount = (price: number, percent: number): string => {
  const discounted = price * (1 - percent / 100)
  return discounted.toFixed(2)
}

// 新增导出：下游可能需要使用
export const formatCurrency = (amount: number, currency: string = 'CNY'): string => {
  const symbols: Record<string, string> = { CNY: '¥', USD: '$', EUR: '€' }
  return `${symbols[currency] || ''}${amount.toFixed(2)}`
}
EOF

# 修改 composable 的返回值结构
cat > composables/useFeatureFlag.ts << 'EOF'
// 破坏性变更：重命名返回值 isEnabled -> isActive
// 引用此 composable 的组件会受影响
export const useFeatureFlag = (flagName: string) => {
  const flags = useState<Record<string, boolean>>('feature-flags', () => ({}))

  // 重命名: isEnabled -> isActive（breaking change）
  const isActive = computed(() => flags.value[flagName] ?? false)

  // 修改: 新增必填参数
  const setFlag = (name: string, value: boolean, reason: string) => {
    console.log(`Flag ${name} set to ${value}, reason: ${reason}`)
    flags.value[name] = value
  }

  // 移除了 toggleFlag 方法

  return { isActive, setFlag, flags }
}
EOF

# 引用方文件（验证依赖分析能追踪到）
cat > components/NotificationBell.vue << 'EOF'
<template>
  <div class="notification-bell" v-if="isActive">
    <span class="bell-icon">🔔</span>
    <span v-if="count > 0" class="badge">{{ count }}</span>
  </div>
</template>

<script setup lang="ts">
// 引用了 useFeatureFlag - isEnabled 已被重命名为 isActive
// 这里还在用旧名字，应该被依赖分析标记
const { isActive } = useFeatureFlag('notifications')

const count = ref(0)

onMounted(async () => {
  count.value = await $fetch<number>('/api/notifications/count')
})
</script>
EOF

# 另一个引用方
cat > components/CartSummary.vue << 'EOF'
<template>
  <div class="cart-summary">
    <div v-for="item in items" :key="item.product.id" class="cart-item">
      <span>{{ item.product.name }}</span>
      <span>{{ formatPrice(item.product.price) }}</span>
      <span>x{{ item.quantity }}</span>
    </div>
    <div class="total">
      总计: {{ formatPrice(totalPrice) }}
    </div>
  </div>
</template>

<script setup lang="ts">
// 引用了 formatPrice - 签名已变更
import { formatPrice } from '~/utils/formatPrice'

const { items, totalPrice } = useCart()
</script>

<style scoped>
.cart-summary { padding: 1rem; }
.cart-item { display: flex; justify-content: space-between; padding: 0.5rem 0; }
.total { font-weight: bold; margin-top: 1rem; border-top: 1px solid #e5e7eb; padding-top: 1rem; }
</style>
EOF

git add -A
git commit -m "test: dependency analysis - breaking changes in exports affecting downstream"

echo ""
echo "✅ 代码已提交到 $BRANCH"
echo ""
echo "📋 下一步："
echo "  git push origin $BRANCH"
echo "  gh pr create --base main --head $BRANCH --title 'test: 04-跨文件依赖分析验证'"
echo ""
echo "🔍 验证清单："
echo "  □ formatPrice.ts 审查评论提及 CartSummary.vue / ProductCard.vue"
echo "  □ useFeatureFlag.ts 评论提及 NotificationBell.vue"
echo "  □ 依赖分析摘要列出受影响的文件列表"
echo "  □ calculateDiscount 返回类型从 number→string 被标记为破坏性"
echo "  □ isEnabled→isActive 重命名被检测到"
SCRIPT

# ============================================================================
# 05 - Linter/SAST 集成
# 测试功能: enable_lint_tools、enable_eslint、enable_biome、enable_tsc、
#           enable_prettier、enable_semgrep、工具归因卡片
# ============================================================================

cat > "$BRANCH_DIR/05-lint-sast.sh" << 'SCRIPT'
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
SCRIPT

# ============================================================================
# 06 - AI 工具 (Web Search + Shell)
# 测试功能: enable_web_search、enable_shell
# ============================================================================

cat > "$BRANCH_DIR/06-ai-tools.sh" << 'SCRIPT'
#!/bin/bash
# ============================================================================
# 测试组 06: AI 工具 - Web搜索与Shell执行
# ============================================================================
# 验证功能点:
#   - enable_web_search: true（AI 联网验证 API 用法）
#   - enable_shell: true（AI 执行 shell 命令辅助分析）
#   - Analysis chain 中有 web_search/shell 步骤
#   - enable_web_search: false 时无联网行为
#   - enable_shell: false 时无 shell 执行
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-06-ai-tools"
echo "🚀 [06] AI 工具测试（Web Search + Shell）"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 触发 Web Search: 使用冷门/复杂 API ---
cat > composables/useSupabase.ts << 'EOF'
import { createClient, type SupabaseClient } from '@supabase/supabase-js'

// 触发 web_search: Supabase SSR 用法是否正确？
// AI 应联网查询 @supabase/supabase-js v2 在 Nuxt3 SSR 环境下的正确用法
let instance: SupabaseClient | null = null

export const useSupabase = () => {
  const config = useRuntimeConfig()

  // 潜在问题：全局单例在 SSR 下跨请求共享状态
  // AI 需要联网确认这是否是反模式
  if (!instance) {
    instance = createClient(
      config.public.supabaseUrl as string,
      config.public.supabaseAnonKey as string,
      {
        auth: {
          // 触发 web_search: autoRefreshToken 在 SSR 下的行为
          autoRefreshToken: true,
          persistSession: true,
          // 触发 web_search: detectSessionInUrl 是否已废弃
          detectSessionInUrl: true
        }
      }
    )
  }

  // 触发 web_search: Supabase realtime 在 SSR 下能用吗？
  const subscribeToChanges = (table: string, callback: (payload: any) => void) => {
    return instance!
      .channel(`public:${table}`)
      .on('postgres_changes', { event: '*', schema: 'public', table }, callback)
      .subscribe()
  }

  return { client: instance!, subscribeToChanges }
}
EOF

# --- 触发 Shell: 依赖版本和配置检查 ---
cat > tsconfig.json << 'EOF'
{
  "extends": "./.nuxt/tsconfig.json",
  "compilerOptions": {
    "strict": true,
    "noEmit": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": true
  },
  "include": ["**/*.ts", "**/*.vue"],
  "exclude": ["node_modules", "dist"]
}
EOF

cat > eslint.config.js << 'EOF'
import globals from 'globals'

export default [
  {
    languageOptions: {
      globals: { ...globals.browser, ...globals.node }
    },
    rules: {
      'no-unused-vars': 'warn',
      'no-console': 'off',
      'eqeqeq': 'error'
    }
  }
]
EOF

# --- 触发 Web Search: 使用最新但文档易混淆的 API ---
cat > utils/api-client.ts << 'EOF'
// 触发 web_search: fetch API 的 signal + AbortController 在 Node.js 下的兼容性
export const createApiClient = (baseUrl: string) => {
  const controller = new AbortController()

  const request = async (path: string, options?: RequestInit) => {
    // 触发 web_search: Node.js fetch 是否支持 keepalive?
    const response = await fetch(`${baseUrl}${path}`, {
      ...options,
      signal: controller.signal,
      keepalive: true,
      // 触发 web_search: priority 是否为标准属性？
      priority: 'high' as any
    })

    if (!response.ok) {
      // 触发 web_search: Response.json() 在非 JSON 响应时的行为
      const error = await response.json()
      throw new Error(error.message)
    }

    return response.json()
  }

  return { request, abort: () => controller.abort() }
}
EOF

git add -A
git commit -m "test: AI tools - web search triggers (Supabase SSR, fetch API) + shell triggers"

echo ""
echo "✅ 代码已提交到 $BRANCH"
echo ""
echo "📋 下一步："
echo "  git push origin $BRANCH"
echo "  gh pr create --base main --head $BRANCH --title 'test: 06-AI工具(Web搜索+Shell)验证'"
echo ""
echo "🔍 验证清单："
echo "  □ AI 评论引用了联网查询结果（如 Supabase 文档）"
echo "  □ Analysis chain 中出现 web_search 步骤"
echo "  □ AI 可能执行 shell 检查 tsconfig/eslint 配置"
echo "  □ Analysis chain 中出现 shell 步骤"
echo "  □ [对比] enable_web_search: false 时无联网内容"
echo "  □ [对比] enable_shell: false 时无 shell 内容"
SCRIPT

# ============================================================================
# 07 - 命令系统
# 测试功能: help、review、full review、summary、pause、resume、
#           resolve、configuration、command_ack_reaction、权限、限流
# ============================================================================

cat > "$BRANCH_DIR/07-commands.sh" << 'SCRIPT'
#!/bin/bash
# ============================================================================
# 测试组 07: 命令系统
# ============================================================================
# 验证功能点:
#   - @codesentinel help（展示所有命令）
#   - @ai-reviewer help（别名触发）
#   - @codesentinel review（增量审查）
#   - @codesentinel full review（全量审查）
#   - @codesentinel summary（重新生成摘要）
#   - @codesentinel pause / resume（暂停/恢复审查）
#   - @codesentinel resolve（批量解决 Bot 评论）
#   - @codesentinel configuration（展示当前配置）
#   - command_ack_reaction: rocket（🚀 表情确认）
#   - 无效命令错误反馈
#   - 大小写不敏感
#   - Bot 自身评论不触发
#   - 速率限制
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-07-commands"
echo "🚀 [07] 命令系统测试"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 生成包含问题的代码（让 Bot 产出评论供 resolve 测试）---
cat > utils/command-test-trigger.ts << 'EOF'
// 此文件目的：让 Bot 产出多条行级评论，用于后续 resolve 命令测试

// 问题1: SQL 注入
export const searchProducts = (keyword: string) => {
  return `SELECT * FROM products WHERE name LIKE '%${keyword}%'`
}

// 问题2: 密码明文比较
export const checkPassword = (input: string, stored: string) => {
  return input === stored
}

// 问题3: Math.random 用作安全用途
export const generateSessionId = () => {
  return Math.random().toString(36).substring(2, 15)
}

// 问题4: 无错误处理
export const fetchData = async (url: string) => {
  const res = await fetch(url)
  return res.json()
}

// 问题5: 竞态条件
let balance = 1000
export const withdraw = async (amount: number) => {
  if (balance >= amount) {
    await new Promise(r => setTimeout(r, 100))
    balance -= amount
    return true
  }
  return false
}
EOF

git add -A
git commit -m "test: commands - trigger code for bot to produce review comments"

echo ""
echo "✅ 代码已提交到 $BRANCH"
echo ""
echo "📋 下一步："
echo "  git push origin $BRANCH"
echo "  gh pr create --base main --head $BRANCH --title 'test: 07-命令系统验证'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 命令测试脚本（在 PR 评论中按顺序执行）："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "== 第 1 步: 等待 Bot 首次自动审查完成 =="
echo ""
echo "== 第 2 步: 命令解析与路由 =="
echo "  评论: @codesentinel help"
echo "  验证: □ 展示所有命令用法"
echo "        □ 评论上出现 🚀 ACK 表情"
echo ""
echo "  评论: @ai-reviewer help"
echo "  验证: □ 别名同样触发"
echo ""
echo "  评论: @CodeSentinel HELP"
echo "  验证: □ 大小写不敏感"
echo ""
echo "  评论: @codesentinel invalidcommand"
echo "  验证: □ 回帖提示无效命令"
echo ""
echo "== 第 3 步: 配置与摘要 =="
echo "  评论: @codesentinel configuration"
echo "  验证: □ 展示当前配置表格"
echo ""
echo "  评论: @codesentinel summary"
echo "  验证: □ 重新生成 PR 摘要"
echo ""
echo "== 第 4 步: resolve 命令 =="
echo "  评论: @codesentinel resolve"
echo "  验证: □ 批量解决 Bot 评论"
echo "        □ 回帖统计: 成功 N 条"
echo ""
echo "== 第 5 步: 暂停/恢复 =="
echo "  评论: @codesentinel pause"
echo "  验证: □ PR 描述写入暂停标记"
echo ""
echo "  操作: push 新 commit（修改任一文件）"
echo "  验证: □ Bot 不自动触发审查"
echo ""
echo "  评论: @codesentinel resume"
echo "  验证: □ 恢复审查标记"
echo ""
echo "  操作: push 新 commit"
echo "  验证: □ Bot 重新触发审查"
echo ""
echo "== 第 6 步: review 命令 =="
echo "  评论: @codesentinel review"
echo "  验证: □ 触发增量审查"
echo ""
echo "  评论: @codesentinel full review"
echo "  验证: □ 从 base 全量审查"
echo ""
echo "== 第 7 步: 限流测试 =="
echo "  快速连续发送 5 次: @codesentinel help"
echo "  验证: □ 第 N 次被限流，提示重试时间"
echo ""
SCRIPT

# ============================================================================
# 08 - 对话追问
# 测试功能: 行级评论追问、Thread 上下文、轮次限制
# ============================================================================

cat > "$BRANCH_DIR/08-conversation.sh" << 'SCRIPT'
#!/bin/bash
# ============================================================================
# 测试组 08: 对话式追问交互
# ============================================================================
# 验证功能点:
#   - @codesentinel <问题>（在行级评论中追问）
#   - Bot 回复引用该行代码上下文
#   - 续轮追问包含历史对话
#   - 不带 @bot 的普通回复不触发
#   - Bot 自身回帖不自触发（无无限循环）
#   - 连续追问达到 10 轮后提示上限
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-08-conversation"
echo "🚀 [08] 对话追问测试"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 产出有深度可追问的代码 ---
cat > utils/date-helper.ts << 'EOF'
// 此文件的目的是让 Bot 产出行级评论后，在评论 thread 中追问

// 复杂的日期处理逻辑（适合追问"为什么这样不好"）
export const getRelativeTime = (date: Date): string => {
  const now = new Date()
  const diff = now.getTime() - date.getTime()

  // 问题：没有考虑时区和 DST
  const seconds = Math.floor(diff / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)

  if (days > 0) return `${days}天前`
  if (hours > 0) return `${hours}小时前`
  if (minutes > 0) return `${minutes}分钟前`
  return '刚刚'
}

// 问题：硬编码中国时区，无国际化
export const formatOrderDate = (isoString: string): string => {
  const date = new Date(isoString)
  return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()} ${date.getHours()}:${date.getMinutes()}`
}

// 问题：月份天数计算不准确
export const getDaysInMonth = (year: number, month: number): number => {
  // 没有处理闰年特殊情况
  const daysPerMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  return daysPerMonth[month]
}

// 问题：日期比较使用字符串比较
export const isDateBefore = (a: string, b: string): boolean => {
  return a < b
}

// 复杂业务逻辑（适合追问"怎么改"）
export const calculateBusinessDays = (start: Date, end: Date): number => {
  let count = 0
  const current = new Date(start)
  while (current <= end) {
    const day = current.getDay()
    if (day !== 0 && day !== 6) {
      count++
    }
    current.setDate(current.getDate() + 1)
  }
  return count
}
EOF

# 更复杂的架构问题文件（适合追问架构层面的问题）
cat > middleware/admin.ts << 'EOF'
// 问题：前端权限检查不可靠（可被绕过）
// 适合追问"前端权限校验有什么风险"
export default defineNuxtRouteMiddleware((to) => {
  const { user } = useAuth()

  // 问题1: 仅前端检查，无后端验证
  if (to.path.startsWith('/admin')) {
    if (!user.value || user.value.role !== 'admin') {
      return navigateTo('/login')
    }
  }

  // 问题2: 角色硬编码
  const adminPaths = ['/admin', '/dashboard/settings', '/users/manage']
  const requiresAdmin = adminPaths.some(p => to.path.startsWith(p))

  if (requiresAdmin && user.value?.role !== 'admin') {
    return navigateTo('/')
  }
})
EOF

git add -A
git commit -m "test: conversation - deep logic for follow-up questions in review threads"

echo ""
echo "✅ 代码已提交到 $BRANCH"
echo ""
echo "📋 下一步："
echo "  git push origin $BRANCH"
echo "  gh pr create --base main --head $BRANCH --title 'test: 08-对话追问交互验证'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 对话追问测试脚本（Bot 产出行级评论后执行）："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "== 第 1 步: 等待 Bot 产出行级评论 =="
echo ""
echo "== 第 2 步: 基础追问（在 Bot 的某条行级评论 thread 中）=="
echo "  回复: @codesentinel 为什么这样写不好？"
echo "  验证: □ Bot 回复解释原因"
echo "        □ 回复引用该行代码上下文"
echo ""
echo "== 第 3 步: 续轮追问 =="
echo "  回复: @codesentinel 那应该怎么改？给个代码示例"
echo "  验证: □ Bot 回复包含修改建议和代码"
echo "        □ 回复引用之前的对话上下文"
echo ""
echo "== 第 4 步: 不触发验证 =="
echo "  回复: 好的我知道了（不带 @bot）"
echo "  验证: □ Bot 不回复"
echo ""
echo "== 第 5 步: 跨行追问 =="
echo "  在 date-helper.ts 的评论中回复:"
echo "  @codesentinel 这整个日期处理模块应该怎么重构？"
echo "  验证: □ Bot 回复能感知文件整体变更"
echo ""
echo "== 第 6 步: [可选] 轮次上限测试 =="
echo "  在同一 thread 连续追问 10+ 轮"
echo "  验证: □ 第 11 轮提示轮次已达上限"
echo ""
SCRIPT

# ============================================================================
# 09 - 增量审查
# 测试功能: 增量 diff、last_reviewed_sha、full review 命令
# ============================================================================

cat > "$BRANCH_DIR/09-incremental.sh" << 'SCRIPT'
#!/bin/bash
# ============================================================================
# 测试组 09: 增量审查
# ============================================================================
# 验证功能点:
#   - 首次审查后 push 新 commit → 仅审查新增变更
#   - 摘要评论中记录已审查 commit（隐藏标签含 commit ID）
#   - @codesentinel review（触发增量审查）
#   - @codesentinel full review（从 base 到 HEAD 全量审查）
#   - 不重复审查旧代码
# ============================================================================
#
# ⚠️ 此测试需要分两次提交：
#   第一次：运行此脚本，push + 创建 PR，等待 Bot 完成首次审查
#   第二次：运行 09-incremental-step2.sh，push 新 commit，验证增量
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-09-incremental"
echo "🚀 [09] 增量审查测试 - Step 1"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 第一次提交：初始问题代码 ---
cat > utils/incremental-base.ts << 'EOF'
// 第一次提交的文件（Bot 首次审查会覆盖这里的问题）

// 问题: eval
export const evaluate = (expr: string) => eval(expr)

// 问题: SQL 注入
export const findById = (id: string) => `SELECT * FROM items WHERE id = '${id}'`

// 正确代码（不应产出评论）
export const safeAdd = (a: number, b: number): number => a + b
EOF

git add -A
git commit -m "test: incremental review step 1 - initial code with issues"

echo ""
echo "✅ Step 1 已提交到 $BRANCH"
echo ""
echo "📋 操作步骤："
echo "  1. git push origin $BRANCH"
echo "  2. gh pr create --base main --head $BRANCH --title 'test: 09-增量审查验证'"
echo "  3. 等待 Bot 完成首次审查"
echo "  4. 确认首次审查覆盖了 eval + SQL 注入"
echo "  5. 运行 ./test-branches/09-incremental-step2.sh 进行第二步"
echo ""
SCRIPT

# --- 增量审查 Step 2 ---
cat > "$BRANCH_DIR/09-incremental-step2.sh" << 'SCRIPT'
#!/bin/bash
# ============================================================================
# 测试组 09: 增量审查 - Step 2
# ============================================================================
# 前提：09-incremental.sh 已执行，PR 已创建，Bot 已完成首次审查
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-09-incremental"
echo "🚀 [09] 增量审查测试 - Step 2"

git checkout "$BRANCH"

# --- 第二次提交：新增问题代码（仅此部分应被增量审查）---
cat > utils/incremental-new.ts << 'EOF'
// 第二次提交的新文件（增量审查应只覆盖这个文件）

// 新问题: SSRF
export const fetchExternal = async (url: string) => {
  return await fetch(url).then(r => r.json())
}

// 新问题: 原型污染
export const deepSet = (obj: any, path: string, value: any) => {
  const keys = path.split('.')
  let current = obj
  for (let i = 0; i < keys.length - 1; i++) {
    if (!current[keys[i]]) current[keys[i]] = {}
    current = current[keys[i]]
  }
  current[keys[keys.length - 1]] = value
}
EOF

# 修改已有文件（添加新函数）
cat >> utils/incremental-base.ts << 'EOF'

// 新增函数（增量审查应覆盖此处）
// 问题: 命令注入
import { execSync } from 'child_process'
export const ping = (host: string) => execSync(`ping -c 1 ${host}`).toString()
EOF

git add -A
git commit -m "test: incremental review step 2 - new issues for delta review"

echo ""
echo "✅ Step 2 已提交"
echo ""
echo "📋 操作步骤："
echo "  1. git push origin $BRANCH"
echo "  2. 等待 Bot 增量审查（或执行 @codesentinel review）"
echo ""
echo "🔍 验证清单："
echo "  □ Bot 仅审查 incremental-new.ts + incremental-base.ts 的新增部分"
echo "  □ 不重复评论 Step 1 的 eval / SQL 注入"
echo "  □ 摘要中记录 commit 范围（上次审查 SHA → 本次 HEAD）"
echo "  □ 执行 @codesentinel full review 后从 base 全量审查"
SCRIPT

# ============================================================================
# 10 - 国际化与 Bot 身份
# 测试功能: language (zh-CN)、bot_icon、bot_name、bot_github_login
# ============================================================================

cat > "$BRANCH_DIR/10-i18n-identity.sh" << 'SCRIPT'
#!/bin/bash
# ============================================================================
# 测试组 10: 国际化与 Bot 身份
# ============================================================================
# 验证功能点:
#   - language: zh-CN（所有评论/摘要用中文输出）
#   - bot_icon: 🦉（Bot 评论中的图标）
#   - bot_name: CodeSentinel（评论中的名称）
#   - bot_github_login（Bot 识别用于 resolve）
#   - 严重级别中文标签
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-10-i18n"
echo "🚀 [10] 国际化与 Bot 身份测试"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 包含各种问题的代码（验证输出语言）---
cat > utils/i18n-test.ts << 'EOF'
// 此文件让 Bot 产出评论，用于验证输出是否为中文

// 安全问题（应产出中文 critical 评论）
export const login = (user: string, pass: string) => {
  // 硬编码凭据
  if (user === 'admin' && pass === 'admin123') {
    return { token: 'fake-token' }
  }
  return null
}

// 性能问题（应产出中文 major 评论）
export const slowSearch = (items: any[], query: string) => {
  return items.filter(item => {
    return JSON.stringify(item).includes(query)
  })
}

// 逻辑问题（应产出中文 minor 评论）
export const divide = (a: number, b: number) => {
  return a / b  // 未处理除零
}
EOF

git add -A
git commit -m "test: i18n - verify Chinese output and bot identity"

echo ""
echo "✅ 代码已提交到 $BRANCH"
echo ""
echo "📋 下一步："
echo "  git push origin $BRANCH"
echo "  gh pr create --base main --head $BRANCH --title 'test: 10-国际化与Bot身份验证'"
echo ""
echo "🔍 验证清单："
echo "  □ PR 摘要评论为中文（Walkthrough/Changes 内容中文）"
echo "  □ 行级评论为中文描述"
echo "  □ 严重级别使用中文标签（如 🚨 严重 / ⚠️ 重要 / 💡 建议）"
echo "  □ 评论中含 Bot 名称 'CodeSentinel'"
echo "  □ 评论中含 Bot 图标 🦉"
echo "  □ Release Notes 为中文"
echo "  □ help 命令输出为中文"
SCRIPT

# ============================================================================
# 11 - 模型配置
# 测试功能: openai_light_model、openai_heavy_model、temperature、retries、
#           timeout、concurrency
# ============================================================================

cat > "$BRANCH_DIR/11-model-config.sh" << 'SCRIPT'
#!/bin/bash
# ============================================================================
# 测试组 11: 模型配置验证
# ============================================================================
# 验证功能点:
#   - openai_light_model: gpt-5.4-nano（摘要用）
#   - openai_heavy_model: gpt-5.4-mini（审查用）
#   - openai_model_temperature: 0.0
#   - openai_retries: 5（重试次数）
#   - openai_timeout_ms: 360000（超时）
#   - openai_concurrency_limit: 6（并发）
#   - github_concurrency_limit: 6（GitHub API 并发）
# ============================================================================
#
# ⚠️ 此测试主要通过观察 Action 日志验证，不需要特殊代码。
#    使用 01-core-review 的 PR 即可，检查 GitHub Actions 日志。
# ============================================================================

set -e
echo "🚀 [11] 模型配置验证"
echo ""
echo "此测试不需要单独分支，通过观察 GitHub Actions 日志验证："
echo ""
echo "🔍 验证清单（在 Actions 运行日志中检查）："
echo "  □ 日志显示使用 gpt-5.4-nano 进行文件摘要"
echo "  □ 日志显示使用 gpt-5.4-mini 进行代码审查"
echo "  □ 超时/重试配置生效（如遇 API 错误会重试 5 次）"
echo "  □ 并发请求数不超过 6"
echo ""
echo "📋 如需测试不同配置，修改 .github/workflows/ 中的 Action 参数："
echo ""
echo "  - name: AI Reviewer"
echo "    uses: syzhangzhinan/ai-reviewer@main"
echo "    with:"
echo "      openai_light_model: 'gpt-5.4-nano'"
echo "      openai_heavy_model: 'gpt-5.4-mini'"
echo "      openai_model_temperature: '0.0'"
echo "      openai_retries: '3'              # 改为 3 对比默认 5"
echo "      openai_timeout_ms: '120000'      # 改为 2分钟 对比默认 6分钟"
echo "      openai_concurrency_limit: '3'    # 改为 3 对比默认 6"
echo ""
SCRIPT

# ============================================================================
# 设置可执行权限
# ============================================================================

chmod +x "$BRANCH_DIR"/*.sh

echo ""
echo "============================================================"
echo " ✅ 所有测试脚本已生成！"
echo "============================================================"
echo ""
echo "📁 输出目录: $BRANCH_DIR/"
echo ""
echo "📂 脚本列表："
echo "  ├── 01-core-review.sh        核心审查流程"
echo "  ├── 02-noise-control.sh      噪音控制与截断"
echo "  ├── 03-path-filters.sh       路径过滤"
echo "  ├── 04-dependency.sh         跨文件依赖分析"
echo "  ├── 05-lint-sast.sh          Linter/SAST 集成"
echo "  ├── 06-ai-tools.sh           AI 工具(Web搜索+Shell)"
echo "  ├── 07-commands.sh           命令系统"
echo "  ├── 08-conversation.sh       对话追问"
echo "  ├── 09-incremental.sh        增量审查 Step 1"
echo "  ├── 09-incremental-step2.sh  增量审查 Step 2"
echo "  ├── 10-i18n-identity.sh      国际化与 Bot 身份"
echo "  └── 11-model-config.sh       模型配置（观察日志）"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 推荐执行顺序："
echo ""
echo "  1️⃣  ./test-branches/01-core-review.sh"
echo "      → 确认 Bot 基础审查功能正常"
echo ""
echo "  2️⃣  并行执行（独立功能）："
echo "      ./test-branches/02-noise-control.sh"
echo "      ./test-branches/03-path-filters.sh"
echo "      ./test-branches/04-dependency.sh"
echo "      ./test-branches/05-lint-sast.sh"
echo "      ./test-branches/06-ai-tools.sh"
echo "      ./test-branches/10-i18n-identity.sh"
echo ""
echo "  3️⃣  需要 Bot 先产出评论后执行："
echo "      ./test-branches/07-commands.sh"
echo "      ./test-branches/08-conversation.sh"
echo ""
echo "  4️⃣  分步执行："
echo "      ./test-branches/09-incremental.sh"
echo "      （等待首次审查完成后）"
echo "      ./test-branches/09-incremental-step2.sh"
echo ""
echo "  5️⃣  观察 Actions 日志："
echo "      ./test-branches/11-model-config.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔧 Action 配置参考（.github/workflows/ai-review.yml）："
echo ""
echo "  对比测试时可切换以下参数："
echo "    disable_review: 'true'              # 仅摘要无审查"
echo "    disable_release_notes: 'true'       # 不生成 Release Notes"
echo "    enable_lint_tools: 'false'          # 关闭所有 lint"
echo "    enable_dependency_analysis: 'false' # 关闭依赖分析"
echo "    enable_web_search: 'false'          # 关闭联网搜索"
echo "    enable_shell: 'false'               # 关闭 shell 执行"
echo "    enable_semgrep: 'true'              # 开启 Semgrep"
echo "    max_review_comments: '5'            # 限制为 5 条测试截断"
echo "    max_files: '3'                      # 限制为 3 文件测试跳过"
echo ""
