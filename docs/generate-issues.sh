#!/bin/bash
# ============================================================================
# AI Reviewer 测试项目 - 问题代码引入脚本
# ============================================================================
# 目标：在已有基线代码上覆盖引入各类问题，用于触发 ai-reviewer 所有功能点。
# 必须在 generate-base.sh 生成的基线之上运行。
#
# 使用方式：
#   git checkout -b feature/test-v2   （或已有 feature 分支）
#   chmod +x docs/generate-issues.sh
#   ./docs/generate-issues.sh
#   git add -A && git commit -m "feat: introduce intentional issues for ai-reviewer testing"
#   gh pr create --base main
# ============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "🐛 开始引入问题代码（覆盖基线文件）..."
echo "📁 项目目录: $PROJECT_DIR"

# ============================================================================
# 触发功能：跨文件依赖分析 (enable_dependency_analysis)
# 策略：修改 utils/formatPrice.ts 导出的函数签名和实现
# ============================================================================

echo "📦 [依赖分析] 替换 utils/formatPrice.ts（破坏接口）..."

cat > utils/formatPrice.ts << 'EOF'
// 问题：移除了 Intl.NumberFormat，改用不安全的 toFixed 拼接
export const formatPrice = (price: number): string => {
  return `¥${price.toFixed(2)}`
}

// 问题：没有处理负数和溢出，移除了边界校验
export const calculateDiscount = (price: number, discountPercent: number): number => {
  return price * (1 - discountPercent / 100)
}

// 问题：硬编码币种判断，移除了 Intl 支持
export const formatCurrency = (amount: number, currency: string = 'CNY'): string => {
  if (currency === 'CNY') return `¥${amount.toFixed(2)}`
  if (currency === 'USD') return `$${amount.toFixed(2)}`
  return `${amount.toFixed(2)} ${currency}`
}
EOF

echo "📦 [依赖分析] 替换 utils/crypto-helper.ts（破坏安全实现）..."

cat > utils/crypto-helper.ts << 'EOF'
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
EOF

# ============================================================================
# 触发功能：跨文件依赖分析（修改 ProductCard 引入依赖）
# ============================================================================

echo "📦 [依赖分析] 替换 components/ProductCard.vue..."

cat > components/ProductCard.vue << 'EOF'
<template>
  <div class="product-card" @click="goToProduct">
    <img :src="product.imageUrl" :alt="product.name" class="product-image" />
    <div class="product-info">
      <h3>{{ product.name }}</h3>
      <p class="price">{{ formatPrice(product.price) }}</p>
      <p class="discount" v-if="discountedPrice">折后: {{ formatPrice(discountedPrice) }}</p>
      <p class="stock" :class="{ 'low-stock': product.stock < 5 }">
        库存: {{ product.stock }}
      </p>
      <BaseButton variant="primary" size="sm" @click.stop="handleAddToCart">
        加入购物车
      </BaseButton>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Product } from '~/types'
import { formatPrice, calculateDiscount } from '~/utils/formatPrice'

const props = defineProps<{
  product: Product
}>()

const { addToCart } = useCart()
const router = useRouter()

// 问题：每个商品都无条件算折扣，没有条件判断
const discountedPrice = computed(() => calculateDiscount(props.product.price, 10))

const goToProduct = () => {
  router.push(`/products/${props.product.id}`)
}

const handleAddToCart = () => {
  // 问题：移除了库存检查
  addToCart(props.product)
}
</script>

<style scoped>
.product-card {
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  overflow: hidden;
  cursor: pointer;
  transition: box-shadow 0.2s;
}
.product-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
.product-image { width: 100%; height: 200px; object-fit: cover; }
.product-info { padding: 1rem; }
.price { color: #ef4444; font-size: 1.25rem; font-weight: bold; }
.low-stock { color: #f59e0b; }
</style>
EOF

# ============================================================================
# 触发功能：跨文件依赖 + Semgrep（server login 引用 crypto-helper）
# ============================================================================

echo "📦 [依赖分析+Semgrep] 替换 server/api/auth/login.post.ts..."

cat > server/api/auth/login.post.ts << 'EOF'
import { hashPassword, generateToken, verifyToken } from '~/utils/crypto-helper'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  // 问题：硬编码凭据
  const storedHash = hashPassword('admin123')
  const inputHash = hashPassword(body.password)

  if (body.email === 'admin@test.com' && verifyToken(inputHash, storedHash)) {
    return {
      user: {
        id: '1',
        email: body.email,
        name: 'Admin',
        role: 'admin',
        createdAt: new Date().toISOString()
      },
      // 问题：使用不安全的自定义 token 生成
      token: generateToken(48)
    }
  }

  throw createError({
    statusCode: 401,
    // 问题：错误信息暴露用户是否存在
    statusMessage: '用户不存在或密码错误'
  })
})
EOF

# ============================================================================
# 触发功能：ESLint + TSC（composables 引入类型问题）
# ============================================================================

echo "📦 [ESLint/TSC] 替换 composables/useAuth.ts..."

cat > composables/useAuth.ts << 'EOF'
import type { User } from '~/types'

export const useAuth = () => {
  const user = useState<User | null>('auth-user', () => null)
  const token = useState<string | null>('auth-token', () => null)
  const loading = useState('auth-loading', () => false)

  const login = async (email: string, password: string) => {
    loading.value = true
    try {
      // 问题：密码明文传输
      const response = await $fetch<{ user: User; token: string }>('/api/auth/login', {
        method: 'POST',
        body: { email, password }
      })
      user.value = response.user
      token.value = response.token
      // 问题：token 存储在 localStorage 有 XSS 风险
      if (import.meta.client) {
        localStorage.setItem('auth_token', response.token)
      }
    } catch (error: any) {
      // 问题：暴露服务端错误信息
      throw new Error(error.data?.message || error.message)
    } finally {
      loading.value = false
    }
  }

  const logout = async () => {
    user.value = null
    token.value = null
    if (import.meta.client) {
      localStorage.removeItem('auth_token')
    }
    await navigateTo('/login')
  }

  const register = async (data: { email: string; password: string; name: string }) => {
    // 问题：移除了输入验证
    const response = await $fetch<{ user: User; token: string }>('/api/auth/register', {
      method: 'POST',
      body: data
    })
    user.value = response.user
    token.value = response.token
  }

  return { user, token, loading, login, logout, register }
}
EOF

echo "📦 [ESLint/TSC] 替换 composables/useCart.ts..."

cat > composables/useCart.ts << 'EOF'
import type { CartItem, Product } from '~/types'

export const useCart = () => {
  const items = useState<CartItem[]>('cart-items', () => [])

  const addToCart = (product: Product, quantity: number = 1) => {
    const existing = items.value.find(item => item.product.id === product.id)
    if (existing) {
      // 问题：没有检查库存是否充足
      existing.quantity += quantity
    } else {
      items.value.push({ product, quantity })
    }
    // 问题：直接操作 DOM
    if (import.meta.client) {
      document.title = `(${totalItems.value}) 购物车`
    }
  }

  const removeFromCart = (productId: string) => {
    items.value = items.value.filter(item => item.product.id !== productId)
  }

  const updateQuantity = (productId: string, quantity: number) => {
    // 问题：没有校验 quantity 为负数或零
    const item = items.value.find(item => item.product.id === productId)
    if (item) {
      item.quantity = quantity
    }
  }

  const clearCart = () => {
    items.value = []
  }

  // 问题：浮点数精度问题，移除了 Math.round 处理
  const totalPrice = computed(() => {
    return items.value.reduce((sum, item) => sum + item.product.price * item.quantity, 0)
  })

  const totalItems = computed(() => {
    return items.value.reduce((sum, item) => sum + item.quantity, 0)
  })

  return { items, addToCart, removeFromCart, updateQuantity, clearCart, totalPrice, totalItems }
}
EOF

# ============================================================================
# 触发功能：Semgrep - XSS (v-html)
# ============================================================================

echo "📦 [Semgrep:XSS] 替换 components/ReviewPanel.vue..."

cat > components/ReviewPanel.vue << 'EOF'
<template>
  <div class="review-panel">
    <h3>商品评价</h3>
    <div v-if="reviews.length === 0" class="no-reviews">暂无评价</div>
    <div v-for="review in reviews" :key="review.id" class="review-item">
      <div class="review-header">
        <span class="reviewer">{{ review.userName }}</span>
        <span class="rating">{{ '⭐'.repeat(review.rating) }}</span>
        <span class="date">{{ formatDate(review.createdAt) }}</span>
      </div>
      <!-- 问题：v-html 直接渲染用户输入，XSS 漏洞 -->
      <div class="review-content" v-html="review.content" />
    </div>
    <form @submit.prevent="submitReview" class="review-form">
      <textarea v-model="newReview" placeholder="写下你的评价..." rows="3" />
      <select v-model="newRating">
        <option :value="1">1星</option>
        <option :value="2">2星</option>
        <option :value="3">3星</option>
        <option :value="4">4星</option>
        <option :value="5">5星</option>
      </select>
      <BaseButton variant="primary" type="submit">提交评价</BaseButton>
    </form>
  </div>
</template>

<script setup lang="ts">
interface Review {
  id: string
  userName: string
  rating: number
  content: string
  createdAt: string
}

const props = defineProps<{
  productId: string
}>()

const reviews = ref<Review[]>([])
const newReview = ref('')
const newRating = ref(5)

const fetchReviews = async () => {
  // 问题：没有分页
  reviews.value = await $fetch<Review[]>(`/api/products/${props.productId}/reviews`)
}

// 问题：没有国际化
const formatDate = (dateStr: string) => {
  return new Date(dateStr).toLocaleDateString()
}

const submitReview = async () => {
  // 问题：没有防重复提交
  await $fetch(`/api/products/${props.productId}/reviews`, {
    method: 'POST',
    body: { content: newReview.value, rating: newRating.value }
  })
  newReview.value = ''
  await fetchReviews()
}

onMounted(fetchReviews)
</script>

<style scoped>
.review-panel { margin-top: 2rem; }
.review-item { padding: 1rem 0; border-bottom: 1px solid #e5e7eb; }
.review-header { display: flex; gap: 1rem; align-items: center; margin-bottom: 0.5rem; }
.reviewer { font-weight: bold; }
.date { color: #6b7280; font-size: 0.875rem; }
.review-form { margin-top: 1rem; display: flex; flex-direction: column; gap: 0.5rem; }
</style>
EOF

# ============================================================================
# 触发功能：Semgrep - SSRF（新增文件）
# ============================================================================

echo "📦 [Semgrep:SSRF] 新增 server/api/proxy.ts..."

cat > server/api/proxy.ts << 'EOF'
export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const targetUrl = query.url as string

  if (!targetUrl) {
    throw createError({ statusCode: 400, statusMessage: 'Missing url parameter' })
  }

  // 问题 (SSRF)：用户 URL 直接传给 fetch，无白名单
  // 攻击者可访问 http://169.254.169.254/latest/meta-data/
  const response = await fetch(targetUrl)
  const data = await response.text()

  return { status: response.status, body: data }
})
EOF

# ============================================================================
# 触发功能：Semgrep - 命令注入（新增文件）
# ============================================================================

echo "📦 [Semgrep:命令注入] 新增 server/api/render.ts..."

cat > server/api/render.ts << 'EOF'
import { exec } from 'child_process'
import { promisify } from 'util'

const execAsync = promisify(exec)

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const template = body.template as string

  if (!template) {
    throw createError({ statusCode: 400, statusMessage: 'Missing template' })
  }

  // 问题 (命令注入)：用户输入拼接到 shell 命令
  const { stdout } = await execAsync(`echo "${template}" | pandoc -f markdown -t html`)

  return { html: stdout }
})
EOF

# ============================================================================
# 触发功能：Semgrep - 原型污染 / 正则注入 / eval / 路径遍历（新增文件）
# ============================================================================

echo "📦 [Semgrep:原型污染/正则/eval] 新增 utils/object-utils.ts..."

cat > utils/object-utils.ts << 'EOF'
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
EOF

# ============================================================================
# 触发功能：Biome 检测（新增文件）
# ============================================================================

echo "📦 [Biome] 新增 utils/data-transform.ts..."

cat > utils/data-transform.ts << 'EOF'
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
EOF

# ============================================================================
# 触发功能：review_simple_changes: false (triage 跳过)
# 策略：仅修改 types/constants.ts 的版本号（trivial 变更）
# ============================================================================

echo "📦 [Triage] 修改 types/constants.ts（仅改版本号，trivial 变更）..."

cat > types/constants.ts << 'EOF'
export const APP_NAME = 'AI Reviewer Test Store'
export const APP_VERSION = '1.1.0'
export const DEFAULT_PAGE_SIZE = 20
export const MAX_CART_ITEMS = 99
export const SUPPORTED_LANGUAGES = ['zh-CN', 'en-US', 'ja-JP']
export const ORDER_STATUS = ['pending', 'paid', 'shipped', 'completed'] as const
EOF

# ============================================================================
# 触发功能：SSR 问题（base-layer 覆盖）
# ============================================================================

echo "📦 [ESLint/Review] 替换 base-layer/composables/useTheme.ts..."

cat > base-layer/composables/useTheme.ts << 'EOF'
export const useTheme = () => {
  const theme = useState<'light' | 'dark'>('theme', () => 'light')

  const toggleTheme = () => {
    theme.value = theme.value === 'light' ? 'dark' : 'light'
    // 问题：直接操作 DOM，应该用响应式绑定
    document.documentElement.setAttribute('data-theme', theme.value)
    localStorage.setItem('theme', theme.value)
  }

  const initTheme = () => {
    // 问题：SSR 环境下 localStorage 不可用，会崩溃
    const saved = localStorage.getItem('theme') as 'light' | 'dark'
    if (saved) {
      theme.value = saved
    }
  }

  return { theme, toggleTheme, initTheme }
}
EOF

# ============================================================================
# 触发功能：enable_web_search（Supabase 单例 SSR 问题）
# ============================================================================

echo "📦 [Web Search] 替换 composables/useSupabase.ts..."

cat > composables/useSupabase.ts << 'EOF'
import { createClient, type SupabaseClient } from '@supabase/supabase-js'

// 问题：全局单例在 SSR 下跨请求共享状态
let supabaseInstance: SupabaseClient | null = null

export const useSupabase = () => {
  const config = useRuntimeConfig()

  if (!supabaseInstance) {
    supabaseInstance = createClient(
      config.public.supabaseUrl as string,
      config.public.supabaseAnonKey as string
    )
  }

  const uploadFile = async (bucket: string, path: string, file: File) => {
    // 问题：没有文件类型和大小验证
    const { data, error } = await supabaseInstance!.storage
      .from(bucket)
      .upload(path, file)

    if (error) throw error
    return data
  }

  const getPublicUrl = (bucket: string, path: string) => {
    // 问题：路径拼接没有安全校验
    const { data } = supabaseInstance!.storage
      .from(bucket)
      .getPublicUrl(path)

    return data.publicUrl
  }

  return { client: supabaseInstance!, uploadFile, getPublicUrl }
}
EOF

# ============================================================================
# 触发功能：Webhook 签名验证缺失
# ============================================================================

echo "📦 [Review] 替换 server/api/webhook.ts..."

cat > server/api/webhook.ts << 'EOF'
export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const headers = getHeaders(event)

  // 问题：webhook 签名验证完全移除
  const eventType = headers['x-github-event']

  switch (eventType) {
    case 'push':
      console.log('Push event received:', body.ref)
      break
    case 'pull_request':
      console.log('PR event:', body.action, body.pull_request?.title)
      break
    default:
      console.log('Unknown event type:', eventType)
  }

  return { received: true }
})
EOF

# ============================================================================
# 触发功能：订单无验证
# ============================================================================

echo "📦 [Review] 替换 server/api/orders.post.ts..."

cat > server/api/orders.post.ts << 'EOF'
export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  // 问题：没有验证用户身份
  // 问题：没有验证订单总额
  // 问题：没有库存扣减原子性保障
  // 问题：没有幂等性防重复

  const order = {
    id: `ORD-${Date.now()}`,
    userId: 'unknown',
    items: body.items,
    total: body.total,
    status: 'pending',
    createdAt: new Date().toISOString()
  }

  console.log('New order created:', order.id)
  return order
})
EOF

# ============================================================================
# 触发功能：DashboardStats 轮询过频
# ============================================================================

echo "📦 [Review] 替换 components/DashboardStats.vue..."

cat > components/DashboardStats.vue << 'EOF'
<template>
  <div class="dashboard-stats">
    <div class="stat-card" v-for="stat in stats" :key="stat.label">
      <span class="stat-value">{{ stat.value }}</span>
      <span class="stat-label">{{ stat.label }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Stat {
  label: string
  value: string | number
}

const stats = ref<Stat[]>([])
let pollTimer: ReturnType<typeof setInterval> | null = null

const fetchStats = async () => {
  try {
    stats.value = await $fetch<Stat[]>('/api/dashboard/stats')
  } catch {
    // 静默失败
  }
}

onMounted(() => {
  fetchStats()
  // 问题：3 秒轮询太频繁（基线是 30 秒）
  pollTimer = setInterval(fetchStats, 3000)
})

onUnmounted(() => {
  if (pollTimer) clearInterval(pollTimer)
})
</script>

<style scoped>
.dashboard-stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; }
.stat-card { padding: 1.5rem; background: white; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); display: flex; flex-direction: column; align-items: center; }
.stat-value { font-size: 2rem; font-weight: bold; color: #3b82f6; }
.stat-label { color: #6b7280; margin-top: 0.5rem; }
</style>
EOF

# ============================================================================
# 触发功能：Open Redirect + 前端权限问题
# ============================================================================

echo "📦 [Review] 替换 middleware/auth.ts..."

cat > middleware/auth.ts << 'EOF'
export default defineNuxtRouteMiddleware((to, _from) => {
  const { user } = useAuth()

  if (!user.value) {
    // 问题：returnUrl 未编码，可能导致 open redirect
    return navigateTo(`/login?returnUrl=${to.fullPath}`)
  }
})
EOF

# ============================================================================
# 触发功能：analytics GDPR 违规
# ============================================================================

echo "📦 [Review] 替换 plugins/analytics.client.ts..."

cat > plugins/analytics.client.ts << 'EOF'
export default defineNuxtPlugin((nuxtApp) => {
  // 问题：移除了 consent 检查，直接发送用户数据
  nuxtApp.hook('page:finish', () => {
    const route = useRoute()
    const { user } = useAuth()

    // 问题：发送 PII 数据到第三方，无脱敏，无 GDPR 合规
    fetch('https://analytics.example.com/track', {
      method: 'POST',
      body: JSON.stringify({
        page: route.fullPath,
        userId: user.value?.id,
        email: user.value?.email,
        timestamp: Date.now()
      }),
      keepalive: true
    }).catch(() => {})
  })
})
EOF

# ============================================================================
# 触发功能：nuxt.config 敏感信息
# ============================================================================

echo "📦 [Review] 替换 nuxt.config.ts..."

cat > nuxt.config.ts << 'EOF'
export default defineNuxtConfig({
  extends: ['./base-layer'],

  modules: ['@pinia/nuxt', '@vueuse/nuxt'],

  runtimeConfig: {
    // 问题：敏感信息有硬编码默认值
    supabaseServiceKey: 'default-service-key',
    public: {
      apiBase: 'https://api.example.com',
      supabaseUrl: 'https://xxx.supabase.co',
      supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.placeholder'
    }
  },

  devtools: { enabled: true },

  typescript: {
    strict: true
  },

  compatibilityDate: '2024-11-01'
})
EOF

# ============================================================================
echo ""
echo "✅ 问题代码引入完成！"
echo ""
echo "📊 功能覆盖矩阵："
echo "  ├── 跨文件依赖分析: formatPrice 签名变更→ProductCard/CartSummary"
echo "  │                    crypto-helper 实现替换→login.post.ts"
echo "  ├── ESLint: useAuth(any), useCart, 全项目 .ts/.vue"
echo "  ├── Biome: utils/data-transform.ts (==, var, 死代码, void, NaN)"
echo "  ├── TSC: strict 模式下的类型问题"
echo "  ├── Semgrep: proxy.ts(SSRF), render.ts(命令注入),"
echo "  │           object-utils.ts(原型污染/正则注入/eval/路径遍历),"
echo "  │           ReviewPanel(v-html XSS)"
echo "  ├── Triage: types/constants.ts 仅改版本号(trivial)"
echo "  ├── Web Search: @supabase/supabase-js SSR 问题"
echo "  ├── Shell: tsconfig + eslint.config 变更"
echo "  └── 审查覆盖: webhook无签名, 订单无验证, 轮询过频, GDPR违规"
echo ""
echo "📋 下一步操作："
echo "  1. git add -A"
echo "  2. git commit -m 'feat: introduce intentional issues for ai-reviewer testing'"
echo "  3. gh pr create --base main --head $(git branch --show-current)"
echo "  4. 等待 ai-reviewer 触发审查"
echo "  5. 按 docs/command-test-guide.md 执行命令测试"
