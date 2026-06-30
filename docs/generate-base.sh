#!/bin/bash
# ============================================================================
# AI Reviewer 测试项目 - 基线生成脚本（干净正确的代码）
# ============================================================================
# 目标：生成一个完整的 Nuxt.js 项目作为 main 分支基线。
# 代码实现正确、无安全漏洞，作为后续 generate-issues.sh 的对比基础。
#
# 使用方式：
#   git checkout main
#   chmod +x docs/generate-base.sh
#   ./docs/generate-base.sh
#   git add -A && git commit -m "feat: add nuxt.js test project baseline"
#   git push origin main
# ============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "🚀 开始生成 Nuxt.js 基线项目（正确实现）..."
echo "📁 项目目录: $PROJECT_DIR"

# ============================================================================
# 基础层 (base-layer)
# ============================================================================

echo "📦 创建 base-layer..."

mkdir -p base-layer/{components,composables,utils,plugins,middleware,layouts}

# --- base-layer/nuxt.config.ts ---
cat > base-layer/nuxt.config.ts << 'EOF'
export default defineNuxtConfig({
  components: true,
  imports: {
    dirs: ['composables', 'utils']
  }
})
EOF

# --- base-layer/components/AppHeader.vue ---
cat > base-layer/components/AppHeader.vue << 'EOF'
<template>
  <header class="app-header">
    <nav>
      <NuxtLink to="/">首页</NuxtLink>
      <NuxtLink to="/products">商品</NuxtLink>
      <NuxtLink to="/cart">购物车</NuxtLink>
      <NuxtLink to="/dashboard">仪表盘</NuxtLink>
    </nav>
    <div class="user-actions">
      <span v-if="user">{{ user.name }}</span>
      <button @click="handleLogout">退出</button>
    </div>
  </header>
</template>

<script setup lang="ts">
const { user, logout } = useAuth()

const handleLogout = async () => {
  await logout()
  await navigateTo('/login')
}
</script>
EOF

# --- base-layer/components/AppFooter.vue ---
cat > base-layer/components/AppFooter.vue << 'EOF'
<template>
  <footer class="app-footer">
    <p>&copy; {{ currentYear }} AI Reviewer Test Store</p>
    <div class="footer-links">
      <a href="/terms">条款</a>
      <a href="/privacy">隐私</a>
    </div>
  </footer>
</template>

<script setup lang="ts">
const currentYear = new Date().getFullYear()
</script>
EOF

# --- base-layer/composables/useTheme.ts ---
cat > base-layer/composables/useTheme.ts << 'EOF'
export const useTheme = () => {
  const theme = useState<'light' | 'dark'>('theme', () => 'light')

  const toggleTheme = () => {
    theme.value = theme.value === 'light' ? 'dark' : 'light'
  }

  const initTheme = () => {
    if (import.meta.client) {
      const saved = localStorage.getItem('theme') as 'light' | 'dark' | null
      if (saved) {
        theme.value = saved
      }
      watch(theme, (val) => {
        document.documentElement.setAttribute('data-theme', val)
        localStorage.setItem('theme', val)
      }, { immediate: true })
    }
  }

  return { theme, toggleTheme, initTheme }
}
EOF

# --- base-layer/composables/useApi.ts ---
cat > base-layer/composables/useApi.ts << 'EOF'
interface ApiOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE'
  body?: unknown
  headers?: Record<string, string>
}

export const useApi = () => {
  const config = useRuntimeConfig()
  const baseURL = config.public.apiBase as string

  const request = async <T>(endpoint: string, options: ApiOptions = {}): Promise<T> => {
    const { method = 'GET', body, headers = {} } = options

    try {
      const response = await $fetch<T>(`${baseURL}${endpoint}`, {
        method,
        body,
        headers: {
          'Content-Type': 'application/json',
          ...headers
        }
      })
      return response
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Request failed'
      throw new Error(`API Error [${method} ${endpoint}]: ${message}`)
    }
  }

  return { request }
}
EOF

# --- base-layer/utils/logger.ts ---
cat > base-layer/utils/logger.ts << 'EOF'
type LogLevel = 'debug' | 'info' | 'warn' | 'error'

interface LogEntry {
  level: LogLevel
  message: string
  timestamp: number
}

export const createLogger = (prefix: string = '') => {
  const history: LogEntry[] = []

  const log = (level: LogLevel, message: string) => {
    const entry: LogEntry = { level, message, timestamp: Date.now() }
    history.push(entry)

    if (import.meta.dev) {
      const tag = prefix ? `[${prefix}]` : ''
      console[level](`${tag}[${level.toUpperCase()}] ${message}`)
    }
  }

  return {
    debug: (msg: string) => log('debug', msg),
    info: (msg: string) => log('info', msg),
    warn: (msg: string) => log('warn', msg),
    error: (msg: string) => log('error', msg),
    getHistory: () => [...history],
    clear: () => { history.length = 0 }
  }
}

export const logger = createLogger()
EOF

# --- base-layer/utils/validators.ts ---
cat > base-layer/utils/validators.ts << 'EOF'
export const validators = {
  isEmail(value: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
  },

  isPhone(value: string): boolean {
    return /^1[3-9]\d{9}$/.test(value)
  },

  isStrongPassword(value: string): boolean {
    if (value.length < 8) return false
    const hasUpper = /[A-Z]/.test(value)
    const hasLower = /[a-z]/.test(value)
    const hasDigit = /\d/.test(value)
    const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(value)
    return hasUpper && hasLower && hasDigit && hasSpecial
  },

  sanitizeInput(value: string): string {
    return value
      .trim()
      .replace(/[<>&"']/g, (char) => {
        const entities: Record<string, string> = {
          '<': '&lt;', '>': '&gt;', '&': '&amp;',
          '"': '&quot;', "'": '&#x27;'
        }
        return entities[char] || char
      })
  },

  isValidPrice(value: number): boolean {
    return value > 0 && Number.isFinite(value) && Number.isInteger(value * 100)
  }
}
EOF

# --- base-layer/middleware/auth.global.ts ---
cat > base-layer/middleware/auth.global.ts << 'EOF'
export default defineNuxtRouteMiddleware((to, _from) => {
  const { user } = useAuth()
  const publicRoutes = ['/', '/login', '/register', '/products']

  if (!publicRoutes.includes(to.path) && !user.value) {
    return navigateTo('/login')
  }
})
EOF

# --- base-layer/plugins/error-handler.ts ---
cat > base-layer/plugins/error-handler.ts << 'EOF'
export default defineNuxtPlugin((nuxtApp) => {
  nuxtApp.vueApp.config.errorHandler = (error, instance, info) => {
    if (import.meta.dev) {
      console.error('Global error:', error, '\nComponent:', instance, '\nInfo:', info)
    }
    // Production: send to monitoring service
  }

  nuxtApp.hook('vue:error', (error, instance, info) => {
    if (import.meta.dev) {
      console.error('Vue error:', error, '\nComponent:', instance, '\nInfo:', info)
    }
  })
})
EOF

# --- base-layer/layouts/default.vue ---
cat > base-layer/layouts/default.vue << 'EOF'
<template>
  <div class="layout-default">
    <AppHeader />
    <main class="main-content">
      <slot />
    </main>
    <AppFooter />
  </div>
</template>

<style scoped>
.layout-default {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}
.main-content {
  flex: 1;
  padding: 2rem;
}
</style>
EOF

# ============================================================================
# 主项目结构
# ============================================================================

echo "📦 创建主项目结构..."

mkdir -p {components,components/ui,composables,layouts,middleware,pages,pages/products,plugins,server/api,server/api/auth,server/api/products,stores,utils,types,assets/css}

# --- nuxt.config.ts ---
cat > nuxt.config.ts << 'EOF'
export default defineNuxtConfig({
  extends: ['./base-layer'],

  modules: ['@pinia/nuxt', '@vueuse/nuxt'],

  runtimeConfig: {
    supabaseServiceKey: '',
    public: {
      apiBase: '',
      supabaseUrl: '',
      supabaseAnonKey: ''
    }
  },

  devtools: { enabled: true },

  typescript: {
    strict: true
  },

  compatibilityDate: '2024-11-01'
})
EOF

# --- package.json ---
cat > package.json << 'EOF'
{
  "name": "ai-reviewer-test",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "nuxt build",
    "dev": "nuxt dev",
    "generate": "nuxt generate",
    "preview": "nuxt preview",
    "lint": "eslint .",
    "typecheck": "nuxt typecheck"
  },
  "dependencies": {
    "@pinia/nuxt": "^0.5.1",
    "@supabase/supabase-js": "^2.39.0",
    "@vueuse/core": "^10.7.0",
    "@vueuse/nuxt": "^10.7.0",
    "nuxt": "^3.13.0",
    "pinia": "^2.1.7",
    "vue": "^3.4.0",
    "vue-router": "^4.2.5"
  },
  "devDependencies": {
    "@nuxt/eslint": "^0.5.0",
    "eslint": "^9.0.0",
    "typescript": "^5.3.0"
  }
}
EOF

# --- tsconfig.json ---
cat > tsconfig.json << 'EOF'
{
  "extends": "./.nuxt/tsconfig.json",
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true
  }
}
EOF

# --- eslint.config.js ---
cat > eslint.config.js << 'EOF'
import { createConfigForNuxt } from '@nuxt/eslint-config/flat'

export default createConfigForNuxt({})
EOF

# --- .gitignore ---
cat > .gitignore << 'EOF'
node_modules
*.log
.nuxt
.nitro
.cache
.output
.env
dist
.DS_Store
EOF

# ============================================================================
# Types
# ============================================================================

cat > types/index.ts << 'EOF'
export interface User {
  id: string
  email: string
  name: string
  role: 'admin' | 'user' | 'guest'
  createdAt: string
}

export interface Product {
  id: string
  name: string
  price: number
  description: string
  stock: number
  category: string
  imageUrl: string
}

export interface CartItem {
  product: Product
  quantity: number
}

export interface Order {
  id: string
  userId: string
  items: CartItem[]
  total: number
  status: 'pending' | 'paid' | 'shipped' | 'completed'
  createdAt: string
}

export interface ApiResponse<T> {
  data: T
  error?: string
  meta?: {
    total: number
    page: number
    pageSize: number
  }
}
EOF

# --- types/constants.ts ---
cat > types/constants.ts << 'EOF'
export const APP_NAME = 'AI Reviewer Test Store'
export const APP_VERSION = '1.0.0'
export const DEFAULT_PAGE_SIZE = 20
export const MAX_CART_ITEMS = 99
export const SUPPORTED_LANGUAGES = ['zh-CN', 'en-US', 'ja-JP']
export const ORDER_STATUS = ['pending', 'paid', 'shipped', 'completed'] as const
EOF

# --- types/enums.ts ---
cat > types/enums.ts << 'EOF'
export enum UserRole {
  Admin = 'admin',
  User = 'user',
  Guest = 'guest',
}

export enum OrderStatus {
  Pending = 'pending',
  Paid = 'paid',
  Shipped = 'shipped',
  Completed = 'completed',
}

export enum ProductCategory {
  Books = 'books',
  Electronics = 'electronics',
  Clothing = 'clothing',
  Food = 'food',
}
EOF

# ============================================================================
# Composables
# ============================================================================

echo "📦 创建 composables..."

# --- composables/useAuth.ts ---
cat > composables/useAuth.ts << 'EOF'
import type { User } from '~/types'

export const useAuth = () => {
  const user = useState<User | null>('auth-user', () => null)
  const token = useCookie('auth_token', { httpOnly: false, secure: true, sameSite: 'strict' })
  const loading = useState('auth-loading', () => false)

  const login = async (email: string, password: string) => {
    loading.value = true
    try {
      const response = await $fetch<{ user: User; token: string }>('/api/auth/login', {
        method: 'POST',
        body: { email, password }
      })
      user.value = response.user
      token.value = response.token
    } catch (error: unknown) {
      throw new Error('登录失败，请检查邮箱和密码')
    } finally {
      loading.value = false
    }
  }

  const logout = async () => {
    user.value = null
    token.value = null
    await navigateTo('/login')
  }

  const register = async (data: { email: string; password: string; name: string }) => {
    if (!data.email || !data.password || !data.name) {
      throw new Error('请填写所有必填字段')
    }
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

# --- composables/useCart.ts ---
cat > composables/useCart.ts << 'EOF'
import type { CartItem, Product } from '~/types'
import { MAX_CART_ITEMS } from '~/types/constants'

export const useCart = () => {
  const items = useState<CartItem[]>('cart-items', () => [])

  const addToCart = (product: Product, quantity: number = 1) => {
    if (product.stock <= 0) return
    if (quantity <= 0) return

    const existing = items.value.find(item => item.product.id === product.id)
    if (existing) {
      const newQty = existing.quantity + quantity
      if (newQty > product.stock) {
        existing.quantity = product.stock
      } else {
        existing.quantity = newQty
      }
    } else {
      if (items.value.length >= MAX_CART_ITEMS) return
      items.value.push({ product, quantity: Math.min(quantity, product.stock) })
    }
  }

  const removeFromCart = (productId: string) => {
    items.value = items.value.filter(item => item.product.id !== productId)
  }

  const updateQuantity = (productId: string, quantity: number) => {
    if (quantity <= 0) {
      removeFromCart(productId)
      return
    }
    const item = items.value.find(item => item.product.id === productId)
    if (item) {
      item.quantity = Math.min(quantity, item.product.stock)
    }
  }

  const clearCart = () => {
    items.value = []
  }

  const totalPrice = computed(() => {
    return items.value.reduce((sum, item) => {
      return sum + Math.round(item.product.price * 100) * item.quantity / 100
    }, 0)
  })

  const totalItems = computed(() => {
    return items.value.reduce((sum, item) => sum + item.quantity, 0)
  })

  return { items, addToCart, removeFromCart, updateQuantity, clearCart, totalPrice, totalItems }
}
EOF

# --- composables/useFeatureFlag.ts ---
cat > composables/useFeatureFlag.ts << 'EOF'
interface FeatureFlags {
  enableNewCheckout: boolean
  enableDarkMode: boolean
  enableWebSocket: boolean
  maxCartItems: number
}

const DEFAULT_FLAGS: FeatureFlags = {
  enableNewCheckout: false,
  enableDarkMode: true,
  enableWebSocket: false,
  maxCartItems: 99
}

export const useFeatureFlag = () => {
  const flags = useState<FeatureFlags>('feature-flags', () => ({ ...DEFAULT_FLAGS }))
  const loaded = useState('feature-flags-loaded', () => false)

  const isEnabled = (flag: keyof FeatureFlags): boolean => {
    const value = flags.value[flag]
    return typeof value === 'boolean' ? value : false
  }

  const fetchFlags = async () => {
    if (loaded.value) return
    try {
      const response = await $fetch<FeatureFlags>('/api/feature-flags')
      flags.value = response
      loaded.value = true
    } catch {
      console.warn('Failed to fetch feature flags, using defaults')
      flags.value = { ...DEFAULT_FLAGS }
    }
  }

  return { flags, isEnabled, fetchFlags }
}
EOF

# --- composables/useSupabase.ts ---
cat > composables/useSupabase.ts << 'EOF'
import { createClient, type SupabaseClient } from '@supabase/supabase-js'

const ALLOWED_FILE_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
const MAX_FILE_SIZE = 10 * 1024 * 1024 // 10MB

export const useSupabase = () => {
  const config = useRuntimeConfig()
  const client = useState<SupabaseClient | null>('supabase-client', () => null)

  if (!client.value) {
    client.value = createClient(
      config.public.supabaseUrl as string,
      config.public.supabaseAnonKey as string
    )
  }

  const uploadFile = async (bucket: string, path: string, file: File) => {
    if (!ALLOWED_FILE_TYPES.includes(file.type)) {
      throw new Error(`不支持的文件类型: ${file.type}`)
    }
    if (file.size > MAX_FILE_SIZE) {
      throw new Error('文件大小不能超过 10MB')
    }

    const safePath = path.replace(/\.\./g, '').replace(/^\//, '')
    const { data, error } = await client.value!.storage
      .from(bucket)
      .upload(safePath, file)

    if (error) throw error
    return data
  }

  const getPublicUrl = (bucket: string, path: string) => {
    const safePath = path.replace(/\.\./g, '').replace(/^\//, '')
    const { data } = client.value!.storage
      .from(bucket)
      .getPublicUrl(safePath)

    return data.publicUrl
  }

  return { client: client.value!, uploadFile, getPublicUrl }
}
EOF

# ============================================================================
# Components
# ============================================================================

echo "📦 创建 components..."

# --- components/ui/BaseButton.vue ---
cat > components/ui/BaseButton.vue << 'EOF'
<template>
  <button
    :class="['btn', `btn-${variant}`, `btn-${size}`, { 'btn-loading': loading }]"
    :disabled="disabled || loading"
    @click="$emit('click', $event)"
  >
    <span v-if="loading" class="spinner" />
    <slot />
  </button>
</template>

<script setup lang="ts">
defineProps<{
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost'
  size?: 'sm' | 'md' | 'lg'
  loading?: boolean
  disabled?: boolean
}>()

defineEmits<{
  click: [event: MouseEvent]
}>()
</script>

<style scoped>
.btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-primary { background: #3b82f6; color: white; }
.btn-danger { background: #ef4444; color: white; }
.btn-loading { opacity: 0.7; cursor: not-allowed; }
</style>
EOF

# --- components/ui/BaseInput.vue ---
cat > components/ui/BaseInput.vue << 'EOF'
<template>
  <div class="input-wrapper">
    <label v-if="label" :for="inputId">{{ label }}</label>
    <input
      :id="inputId"
      :type="type"
      :value="modelValue"
      :placeholder="placeholder"
      :disabled="disabled"
      @input="handleInput"
    />
    <span v-if="error" class="error-text">{{ error }}</span>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  modelValue?: string | number
  label?: string
  type?: string
  placeholder?: string
  disabled?: boolean
  error?: string
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const inputId = useId()

const handleInput = (event: Event) => {
  const target = event.target as HTMLInputElement
  emit('update:modelValue', target.value)
}
</script>
EOF

# --- components/ProductCard.vue ---
cat > components/ProductCard.vue << 'EOF'
<template>
  <div class="product-card" @click="goToProduct">
    <img :src="product.imageUrl" :alt="product.name" class="product-image" />
    <div class="product-info">
      <h3>{{ product.name }}</h3>
      <p class="price">{{ formattedPrice }}</p>
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
import { formatPrice } from '~/utils/formatPrice'

const props = defineProps<{
  product: Product
}>()

const { addToCart } = useCart()
const router = useRouter()

const formattedPrice = computed(() => formatPrice(props.product.price))

const goToProduct = () => {
  router.push(`/products/${props.product.id}`)
}

const handleAddToCart = () => {
  if (props.product.stock > 0) {
    addToCart(props.product)
  }
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
.product-card:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}
.product-image {
  width: 100%;
  height: 200px;
  object-fit: cover;
}
.product-info {
  padding: 1rem;
}
.price {
  color: #ef4444;
  font-size: 1.25rem;
  font-weight: bold;
}
.low-stock {
  color: #f59e0b;
}
</style>
EOF

# --- components/CartSummary.vue ---
cat > components/CartSummary.vue << 'EOF'
<template>
  <div class="cart-summary">
    <h2>订单摘要</h2>
    <div class="summary-row" v-for="item in items" :key="item.product.id">
      <span>{{ item.product.name }} × {{ item.quantity }}</span>
      <span>{{ formatPrice(item.product.price * item.quantity) }}</span>
    </div>
    <hr />
    <div class="summary-total">
      <strong>总计</strong>
      <strong>{{ formatPrice(totalPrice) }}</strong>
    </div>
    <BaseButton variant="primary" size="lg" :loading="submitting" @click="handleCheckout">
      提交订单
    </BaseButton>
  </div>
</template>

<script setup lang="ts">
import { formatPrice } from '~/utils/formatPrice'

const { items, totalPrice, clearCart } = useCart()
const { user } = useAuth()
const submitting = ref(false)

const handleCheckout = async () => {
  if (!user.value) {
    navigateTo('/login')
    return
  }
  if (items.value.length === 0) return

  submitting.value = true
  try {
    await $fetch('/api/orders', {
      method: 'POST',
      body: {
        items: items.value,
        total: totalPrice.value
      }
    })
    clearCart()
    navigateTo('/orders/success')
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : '提交失败'
    console.error('Checkout failed:', message)
  } finally {
    submitting.value = false
  }
}
</script>

<style scoped>
.cart-summary {
  padding: 1.5rem;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
}
.summary-row {
  display: flex;
  justify-content: space-between;
  padding: 0.5rem 0;
}
.summary-total {
  display: flex;
  justify-content: space-between;
  font-size: 1.25rem;
  margin: 1rem 0;
}
</style>
EOF

# --- components/ReviewPanel.vue ---
cat > components/ReviewPanel.vue << 'EOF'
<template>
  <div class="review-panel">
    <h3>商品评价</h3>
    <div v-if="reviews.length === 0" class="no-reviews">暂无评价</div>
    <div v-for="review in paginatedReviews" :key="review.id" class="review-item">
      <div class="review-header">
        <span class="reviewer">{{ review.userName }}</span>
        <span class="rating">{{ '⭐'.repeat(review.rating) }}</span>
        <span class="date">{{ formatDate(review.createdAt) }}</span>
      </div>
      <p class="review-content">{{ review.content }}</p>
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
      <BaseButton variant="primary" type="submit" :disabled="submitting">提交评价</BaseButton>
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
const submitting = ref(false)
const page = ref(1)
const pageSize = 10

const paginatedReviews = computed(() => {
  return reviews.value.slice(0, page.value * pageSize)
})

const fetchReviews = async () => {
  reviews.value = await $fetch<Review[]>(`/api/products/${props.productId}/reviews`)
}

const formatDate = (dateStr: string) => {
  return new Intl.DateTimeFormat('zh-CN').format(new Date(dateStr))
}

const submitReview = async () => {
  if (submitting.value || !newReview.value.trim()) return
  submitting.value = true
  try {
    await $fetch(`/api/products/${props.productId}/reviews`, {
      method: 'POST',
      body: { content: newReview.value, rating: newRating.value }
    })
    newReview.value = ''
    await fetchReviews()
  } finally {
    submitting.value = false
  }
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

# --- components/DashboardStats.vue ---
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
const { pause, resume } = useIntervalFn(fetchStats, 30000)

async function fetchStats() {
  try {
    stats.value = await $fetch<Stat[]>('/api/dashboard/stats')
  } catch {
    // keep previous stats on failure
  }
}

onMounted(fetchStats)
onUnmounted(pause)
</script>

<style scoped>
.dashboard-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}
.stat-card {
  padding: 1.5rem;
  background: white;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  display: flex;
  flex-direction: column;
  align-items: center;
}
.stat-value { font-size: 2rem; font-weight: bold; color: #3b82f6; }
.stat-label { color: #6b7280; margin-top: 0.5rem; }
</style>
EOF

# --- components/NotificationBell.vue ---
cat > components/NotificationBell.vue << 'EOF'
<template>
  <div class="notification-bell" @click="togglePanel">
    <span class="bell-icon">🔔</span>
    <span v-if="unreadCount > 0" class="badge">{{ unreadCount }}</span>
    <div v-if="showPanel" class="notification-panel">
      <div v-for="notif in notifications" :key="notif.id" class="notif-item"
           :class="{ unread: !notif.read }"
           @click.stop="markAsRead(notif.id)">
        <p>{{ notif.message }}</p>
        <span class="notif-time">{{ notif.createdAt }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Notification {
  id: string
  message: string
  read: boolean
  createdAt: string
}

const showPanel = ref(false)
const notifications = ref<Notification[]>([])

const unreadCount = computed(() => notifications.value.filter(n => !n.read).length)

const togglePanel = () => {
  showPanel.value = !showPanel.value
}

const markAsRead = async (id: string) => {
  try {
    await $fetch(`/api/notifications/${id}/read`, { method: 'POST' })
    const notif = notifications.value.find(n => n.id === id)
    if (notif) notif.read = true
  } catch {
    // revert on failure — already unchanged since we update after success
  }
}

const connectWebSocket = () => {
  if (!import.meta.client) return
  const config = useRuntimeConfig()
  const wsUrl = `${config.public.apiBase.replace('http', 'ws')}/notifications`
  let ws: WebSocket | null = null
  let reconnectTimer: ReturnType<typeof setTimeout> | null = null

  const connect = () => {
    ws = new WebSocket(wsUrl)
    ws.onmessage = (event) => {
      const notif = JSON.parse(event.data) as Notification
      notifications.value.unshift(notif)
    }
    ws.onclose = () => {
      reconnectTimer = setTimeout(connect, 5000)
    }
  }

  connect()
  onUnmounted(() => {
    ws?.close()
    if (reconnectTimer) clearTimeout(reconnectTimer)
  })
}

onMounted(connectWebSocket)
</script>

<style scoped>
.notification-bell { position: relative; cursor: pointer; }
.badge {
  position: absolute; top: -5px; right: -5px;
  background: #ef4444; color: white; border-radius: 50%;
  width: 18px; height: 18px; font-size: 0.75rem;
  display: flex; align-items: center; justify-content: center;
}
.notification-panel {
  position: absolute; top: 100%; right: 0; width: 300px;
  background: white; border: 1px solid #e5e7eb; border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15); max-height: 400px;
  overflow-y: auto; z-index: 100;
}
.notif-item { padding: 0.75rem; border-bottom: 1px solid #f3f4f6; }
.notif-item.unread { background: #eff6ff; }
</style>
EOF

# ============================================================================
# Pages
# ============================================================================

echo "📦 创建 pages..."

# --- pages/index.vue ---
cat > pages/index.vue << 'EOF'
<template>
  <div class="home-page">
    <section class="hero">
      <h1>欢迎来到测试商城</h1>
      <p>AI Reviewer 命令系统测试项目</p>
    </section>
    <section class="featured-products">
      <h2>推荐商品</h2>
      <div class="product-grid">
        <ProductCard v-for="product in products" :key="product.id" :product="product" />
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import type { Product } from '~/types'

useHead({
  title: '首页 - 测试商城',
  meta: [{ name: 'description', content: '这是一个测试商城' }]
})

const { data: products, error } = await useFetch<Product[]>('/api/products', {
  default: () => []
})

if (error.value) {
  console.error('Failed to load products:', error.value)
}
</script>

<style scoped>
.hero {
  text-align: center; padding: 4rem 0;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white; border-radius: 12px; margin-bottom: 2rem;
}
.product-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.5rem;
}
</style>
EOF

# --- pages/products/[id].vue ---
cat > pages/products/[id].vue << 'EOF'
<template>
  <div class="product-detail" v-if="product">
    <div class="product-gallery">
      <img :src="product.imageUrl" :alt="product.name" />
    </div>
    <div class="product-info">
      <h1>{{ product.name }}</h1>
      <p class="price">{{ formatPrice(product.price) }}</p>
      <p class="description">{{ product.description }}</p>
      <div class="quantity-selector">
        <button @click="decreaseQty" :disabled="quantity <= 1">-</button>
        <span>{{ quantity }}</span>
        <button @click="increaseQty" :disabled="quantity >= product.stock">+</button>
      </div>
      <BaseButton variant="primary" @click="handleAdd">加入购物车</BaseButton>
    </div>
    <ReviewPanel :product-id="product.id" />
  </div>
  <div v-else class="loading">加载中...</div>
</template>

<script setup lang="ts">
import type { Product } from '~/types'
import { formatPrice } from '~/utils/formatPrice'

const route = useRoute()
const { addToCart } = useCart()
const quantity = ref(1)

const productId = Array.isArray(route.params.id) ? route.params.id[0] : route.params.id
const { data: product } = await useFetch<Product>(`/api/products/${productId}`)

const increaseQty = () => {
  if (product.value && quantity.value < product.value.stock) {
    quantity.value++
  }
}

const decreaseQty = () => {
  if (quantity.value > 1) quantity.value--
}

const handleAdd = () => {
  if (product.value) {
    addToCart(product.value, quantity.value)
  }
}
</script>

<style scoped>
.product-detail { display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; }
.product-gallery img { width: 100%; border-radius: 8px; }
.price { font-size: 1.5rem; color: #ef4444; font-weight: bold; }
.quantity-selector { display: flex; align-items: center; gap: 1rem; margin: 1rem 0; }
.quantity-selector button {
  width: 32px; height: 32px; border: 1px solid #d1d5db;
  border-radius: 4px; background: white; cursor: pointer;
}
</style>
EOF

# --- pages/cart.vue ---
cat > pages/cart.vue << 'EOF'
<template>
  <div class="cart-page">
    <h1>购物车</h1>
    <div v-if="items.length === 0" class="empty-cart">
      <p>购物车是空的</p>
      <NuxtLink to="/products">去逛逛</NuxtLink>
    </div>
    <div v-else class="cart-layout">
      <div class="cart-items">
        <div v-for="item in items" :key="item.product.id" class="cart-item">
          <img :src="item.product.imageUrl" :alt="item.product.name" class="item-image" />
          <div class="item-info">
            <h3>{{ item.product.name }}</h3>
            <p class="item-price">{{ formatPrice(item.product.price) }}</p>
          </div>
          <div class="item-quantity">
            <button @click="updateQuantity(item.product.id, item.quantity - 1)">-</button>
            <span>{{ item.quantity }}</span>
            <button @click="updateQuantity(item.product.id, item.quantity + 1)">+</button>
          </div>
          <button class="remove-btn" @click="removeFromCart(item.product.id)">删除</button>
        </div>
      </div>
      <CartSummary />
    </div>
  </div>
</template>

<script setup lang="ts">
import { formatPrice } from '~/utils/formatPrice'

const { items, updateQuantity, removeFromCart } = useCart()

useHead({ title: '购物车 - 测试商城' })
</script>

<style scoped>
.cart-layout { display: grid; grid-template-columns: 2fr 1fr; gap: 2rem; }
.cart-item { display: flex; align-items: center; gap: 1rem; padding: 1rem; border-bottom: 1px solid #e5e7eb; }
.item-image { width: 80px; height: 80px; object-fit: cover; border-radius: 4px; }
.item-quantity { display: flex; align-items: center; gap: 0.5rem; }
.remove-btn { color: #ef4444; background: none; border: none; cursor: pointer; }
</style>
EOF

# --- pages/dashboard.vue ---
cat > pages/dashboard.vue << 'EOF'
<template>
  <div class="dashboard-page">
    <h1>仪表盘</h1>
    <DashboardStats />
    <section class="recent-orders">
      <h2>最近订单</h2>
      <table class="orders-table">
        <thead>
          <tr><th>订单号</th><th>金额</th><th>状态</th><th>日期</th></tr>
        </thead>
        <tbody>
          <tr v-for="order in orders" :key="order.id">
            <td>{{ order.id }}</td>
            <td>{{ formatPrice(order.total) }}</td>
            <td><span :class="['status-badge', `status-${order.status}`]">{{ statusMap[order.status] }}</span></td>
            <td>{{ formatOrderDate(order.createdAt) }}</td>
          </tr>
        </tbody>
      </table>
    </section>
  </div>
</template>

<script setup lang="ts">
import type { Order } from '~/types'
import { formatPrice } from '~/utils/formatPrice'

definePageMeta({ middleware: 'auth' })

const statusMap: Record<string, string> = {
  pending: '待支付', paid: '已支付', shipped: '已发货', completed: '已完成'
}

const formatOrderDate = (dateStr: string) => {
  return new Intl.DateTimeFormat('zh-CN').format(new Date(dateStr))
}

const { data: orders } = await useFetch<Order[]>('/api/orders', { default: () => [] })
</script>

<style scoped>
.orders-table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
.orders-table th, .orders-table td { padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb; }
.status-badge { padding: 0.25rem 0.5rem; border-radius: 4px; font-size: 0.875rem; }
.status-pending { background: #fef3c7; color: #92400e; }
.status-paid { background: #d1fae5; color: #065f46; }
.status-shipped { background: #dbeafe; color: #1e40af; }
.status-completed { background: #e5e7eb; color: #374151; }
</style>
EOF

# --- pages/login.vue ---
cat > pages/login.vue << 'EOF'
<template>
  <div class="login-page">
    <form class="login-form" @submit.prevent="handleLogin">
      <h2>登录</h2>
      <BaseInput v-model="email" label="邮箱" type="email" placeholder="请输入邮箱" :error="errors.email" />
      <BaseInput v-model="password" label="密码" type="password" placeholder="请输入密码" :error="errors.password" />
      <BaseButton variant="primary" type="submit" :loading="loading">登录</BaseButton>
      <p class="register-link">没有账号？<NuxtLink to="/register">去注册</NuxtLink></p>
    </form>
  </div>
</template>

<script setup lang="ts">
import { validators } from '~/base-layer/utils/validators'

definePageMeta({ layout: 'auth' })

const { login, loading } = useAuth()
const email = ref('')
const password = ref('')
const errors = reactive({ email: '', password: '' })

const handleLogin = async () => {
  errors.email = ''
  errors.password = ''

  if (!validators.isEmail(email.value)) {
    errors.email = '请输入有效的邮箱地址'
    return
  }
  if (!password.value || password.value.length < 6) {
    errors.password = '密码至少 6 个字符'
    return
  }

  try {
    await login(email.value, password.value)
    navigateTo('/dashboard')
  } catch {
    errors.email = '登录失败，请检查邮箱和密码'
  }
}
</script>

<style scoped>
.login-page { display: flex; justify-content: center; align-items: center; min-height: 80vh; }
.login-form { width: 100%; max-width: 400px; padding: 2rem; border: 1px solid #e5e7eb; border-radius: 8px; }
.register-link { text-align: center; margin-top: 1rem; }
</style>
EOF

# ============================================================================
# Stores (Pinia)
# ============================================================================

echo "📦 创建 stores..."

# --- stores/userStore.ts ---
cat > stores/userStore.ts << 'EOF'
import { defineStore } from 'pinia'
import type { User } from '~/types'

interface UserState {
  currentUser: User | null
  preferences: {
    language: string
    currency: string
    notifications: boolean
  }
}

export const useUserStore = defineStore('user', {
  state: (): UserState => ({
    currentUser: null,
    preferences: { language: 'zh-CN', currency: 'CNY', notifications: true }
  }),

  getters: {
    isAdmin(): boolean { return this.currentUser?.role === 'admin' },
    displayName(): string { return this.currentUser?.name || '游客' }
  },

  actions: {
    setUser(user: User) { this.currentUser = user },

    async updatePreferences(prefs: Partial<UserState['preferences']>) {
      const previous = { ...this.preferences }
      Object.assign(this.preferences, prefs)
      try {
        await $fetch('/api/user/preferences', { method: 'PUT', body: this.preferences })
      } catch {
        this.preferences = previous
      }
    },

    async fetchUser() {
      const user = await $fetch<User>('/api/user/me')
      this.currentUser = user
    }
  }
})
EOF

# --- stores/productStore.ts ---
cat > stores/productStore.ts << 'EOF'
import { defineStore } from 'pinia'
import type { Product } from '~/types'

export const useProductStore = defineStore('products', {
  state: () => ({
    products: [] as Product[],
    loading: false,
    currentPage: 1,
    totalPages: 0,
    searchQuery: '',
    selectedCategory: ''
  }),

  getters: {
    filteredProducts(): Product[] {
      let result = this.products
      if (this.searchQuery) {
        const query = this.searchQuery.toLowerCase()
        result = result.filter(p =>
          p.name.toLowerCase().includes(query) || p.description.toLowerCase().includes(query)
        )
      }
      if (this.selectedCategory) {
        result = result.filter(p => p.category === this.selectedCategory)
      }
      return result
    }
  },

  actions: {
    async fetchProducts(page: number = 1) {
      this.loading = true
      try {
        const response = await $fetch<{ data: Product[]; totalPages: number }>('/api/products', {
          params: { page, pageSize: 20 }
        })
        this.products = response.data
        this.totalPages = response.totalPages
        this.currentPage = page
      } finally {
        this.loading = false
      }
    },

    async deleteProduct(id: string) {
      await $fetch(`/api/products/${id}`, { method: 'DELETE' })
      this.products = this.products.filter(p => p.id !== id)
    }
  }
})
EOF

# ============================================================================
# Server API
# ============================================================================

echo "📦 创建 server API..."

# --- server/api/products/index.get.ts ---
cat > server/api/products/index.get.ts << 'EOF'
import type { Product } from '~/types'

const mockProducts: Product[] = [
  { id: '1', name: 'TypeScript 入门教程', price: 49.9, description: '从零开始学习 TypeScript', stock: 100, category: 'books', imageUrl: '/images/ts-book.png' },
  { id: '2', name: 'Vue.js 实战', price: 69.9, description: 'Vue 3 + Composition API 完整指南', stock: 50, category: 'books', imageUrl: '/images/vue-book.png' },
  { id: '3', name: '机械键盘', price: 299.0, description: '87键 Cherry MX 红轴', stock: 3, category: 'electronics', imageUrl: '/images/keyboard.png' }
]

export default defineEventHandler((event) => {
  const query = getQuery(event)
  const page = Math.max(1, Number(query.page) || 1)
  const pageSize = Math.min(100, Math.max(1, Number(query.pageSize) || 20))

  const start = (page - 1) * pageSize
  const data = mockProducts.slice(start, start + pageSize)

  return { data, totalPages: Math.ceil(mockProducts.length / pageSize) }
})
EOF

# --- server/api/auth/login.post.ts ---
cat > server/api/auth/login.post.ts << 'EOF'
import { createHmac, randomUUID } from 'crypto'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body.email || !body.password) {
    throw createError({ statusCode: 400, statusMessage: '请提供邮箱和密码' })
  }

  // In production: use bcrypt + database lookup
  const storedHash = createHmac('sha256', 'server-secret').update('admin123').digest('hex')
  const inputHash = createHmac('sha256', 'server-secret').update(body.password).digest('hex')

  if (body.email === 'admin@test.com' && storedHash === inputHash) {
    return {
      user: {
        id: '1',
        email: body.email,
        name: 'Admin',
        role: 'admin',
        createdAt: new Date().toISOString()
      },
      token: randomUUID()
    }
  }

  throw createError({ statusCode: 401, statusMessage: '认证失败' })
})
EOF

# --- server/api/webhook.ts ---
cat > server/api/webhook.ts << 'EOF'
import { createHmac, timingSafeEqual } from 'crypto'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const headers = getHeaders(event)
  const signature = headers['x-hub-signature-256']

  if (!signature) {
    throw createError({ statusCode: 401, statusMessage: 'Missing signature' })
  }

  const config = useRuntimeConfig()
  const expected = 'sha256=' + createHmac('sha256', config.webhookSecret || '')
    .update(JSON.stringify(body))
    .digest('hex')

  const sigBuffer = Buffer.from(signature)
  const expectedBuffer = Buffer.from(expected)

  if (sigBuffer.length !== expectedBuffer.length || !timingSafeEqual(sigBuffer, expectedBuffer)) {
    throw createError({ statusCode: 401, statusMessage: 'Invalid signature' })
  }

  const eventType = headers['x-github-event']

  switch (eventType) {
    case 'push':
      break
    case 'pull_request':
      break
  }

  return { received: true }
})
EOF

# --- server/api/orders.post.ts ---
cat > server/api/orders.post.ts << 'EOF'
import { randomUUID } from 'crypto'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body.items || !Array.isArray(body.items) || body.items.length === 0) {
    throw createError({ statusCode: 400, statusMessage: '订单不能为空' })
  }

  const order = {
    id: `ORD-${randomUUID().slice(0, 8)}`,
    userId: 'authenticated-user',
    items: body.items,
    total: body.total,
    status: 'pending',
    createdAt: new Date().toISOString()
  }

  return order
})
EOF

# ============================================================================
# Middleware
# ============================================================================

echo "📦 创建 middleware..."

# --- middleware/auth.ts ---
cat > middleware/auth.ts << 'EOF'
export default defineNuxtRouteMiddleware((to, _from) => {
  const { user } = useAuth()

  if (!user.value) {
    return navigateTo(`/login?returnUrl=${encodeURIComponent(to.fullPath)}`)
  }
})
EOF

# --- middleware/admin.ts ---
cat > middleware/admin.ts << 'EOF'
export default defineNuxtRouteMiddleware((_to, _from) => {
  const { user } = useAuth()

  if (!user.value) {
    return navigateTo('/login')
  }

  if (user.value.role !== 'admin') {
    return abortNavigation()
  }
})
EOF

# ============================================================================
# Plugins
# ============================================================================

echo "📦 创建 plugins..."

# --- plugins/auth.client.ts ---
cat > plugins/auth.client.ts << 'EOF'
export default defineNuxtPlugin(async () => {
  const { user, token } = useAuth()

  if (token.value) {
    try {
      const response = await $fetch<{ user: any }>('/api/auth/verify', {
        headers: { Authorization: `Bearer ${token.value}` }
      })
      user.value = response.user
    } catch {
      token.value = null
    }
  }
})
EOF

# --- plugins/analytics.client.ts ---
cat > plugins/analytics.client.ts << 'EOF'
export default defineNuxtPlugin((nuxtApp) => {
  const consentGiven = useCookie('analytics_consent')

  nuxtApp.hook('page:finish', () => {
    if (!consentGiven.value) return

    const route = useRoute()

    fetch('/api/analytics/track', {
      method: 'POST',
      body: JSON.stringify({
        page: route.path,
        timestamp: Date.now()
      }),
      keepalive: true
    }).catch(() => {})
  })
})
EOF

# ============================================================================
# Utils
# ============================================================================

echo "📦 创建 utils..."

# --- utils/formatPrice.ts ---
cat > utils/formatPrice.ts << 'EOF'
const formatter = new Intl.NumberFormat('zh-CN', {
  style: 'currency',
  currency: 'CNY',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
})

export const formatPrice = (price: number): string => {
  return formatter.format(price)
}

export const calculateDiscount = (price: number, discountPercent: number): number => {
  if (discountPercent < 0 || discountPercent > 100) return price
  return Math.round(price * (100 - discountPercent)) / 100
}

export const formatCurrency = (amount: number, currency: string = 'CNY'): string => {
  return new Intl.NumberFormat('zh-CN', {
    style: 'currency',
    currency,
    minimumFractionDigits: 2
  }).format(amount)
}
EOF

# --- utils/crypto-helper.ts ---
cat > utils/crypto-helper.ts << 'EOF'
export const hashPassword = async (password: string): Promise<string> => {
  const encoder = new TextEncoder()
  const data = encoder.encode(password)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
}

export const generateToken = (length: number = 32): string => {
  const array = new Uint8Array(length)
  crypto.getRandomValues(array)
  return Array.from(array, b => b.toString(16).padStart(2, '0')).join('')
}

export const verifyToken = (provided: string, expected: string): boolean => {
  if (provided.length !== expected.length) return false
  let result = 0
  for (let i = 0; i < provided.length; i++) {
    result |= provided.charCodeAt(i) ^ expected.charCodeAt(i)
  }
  return result === 0
}
EOF

# --- utils/date-helper.ts ---
cat > utils/date-helper.ts << 'EOF'
const dateFormatter = new Intl.DateTimeFormat('zh-CN', { dateStyle: 'short' })
const dateTimeFormatter = new Intl.DateTimeFormat('zh-CN', { dateStyle: 'short', timeStyle: 'short' })

export const formatDate = (date: string | Date): string => {
  return dateFormatter.format(new Date(date))
}

export const formatDateTime = (date: string | Date): string => {
  return dateTimeFormatter.format(new Date(date))
}

const rtf = new Intl.RelativeTimeFormat('zh-CN', { numeric: 'auto' })

export const timeAgo = (date: string | Date): string => {
  const now = Date.now()
  const past = new Date(date).getTime()
  const diffSeconds = Math.floor((now - past) / 1000)

  if (diffSeconds < 60) return rtf.format(-diffSeconds, 'second')
  if (diffSeconds < 3600) return rtf.format(-Math.floor(diffSeconds / 60), 'minute')
  if (diffSeconds < 86400) return rtf.format(-Math.floor(diffSeconds / 3600), 'hour')
  return rtf.format(-Math.floor(diffSeconds / 86400), 'day')
}
EOF

# --- utils/api-client.ts ---
cat > utils/api-client.ts << 'EOF'
interface RequestConfig {
  baseURL?: string
  timeout?: number
  retries?: number
}

class ApiClient {
  private baseURL: string
  private timeout: number
  private retries: number

  constructor(config: RequestConfig = {}) {
    this.baseURL = config.baseURL || ''
    this.timeout = config.timeout || 30000
    this.retries = config.retries || 0
  }

  async get<T>(url: string, params?: Record<string, unknown>): Promise<T> {
    return this.request<T>('GET', url, { params })
  }

  async post<T>(url: string, body?: unknown): Promise<T> {
    return this.request<T>('POST', url, { body })
  }

  async put<T>(url: string, body?: unknown): Promise<T> {
    return this.request<T>('PUT', url, { body })
  }

  async delete<T>(url: string): Promise<T> {
    return this.request<T>('DELETE', url)
  }

  private isIdempotent(method: string): boolean {
    return ['GET', 'PUT', 'DELETE', 'HEAD', 'OPTIONS'].includes(method)
  }

  private async request<T>(method: string, url: string, options: Record<string, unknown> = {}): Promise<T> {
    let lastError: Error | null = null
    const maxAttempts = this.isIdempotent(method) ? this.retries + 1 : 1

    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        const response = await $fetch<T>(`${this.baseURL}${url}`, {
          method: method as any,
          ...options,
          timeout: this.timeout
        })
        return response
      } catch (error: unknown) {
        lastError = error instanceof Error ? error : new Error(String(error))
        if (attempt < maxAttempts - 1) {
          const delay = Math.min(1000 * Math.pow(2, attempt), 10000)
          await new Promise(resolve => setTimeout(resolve, delay))
        }
      }
    }

    throw lastError
  }
}

export const apiClient = new ApiClient({
  baseURL: '/api',
  retries: 3,
  timeout: 10000
})
EOF

# ============================================================================
# Layouts
# ============================================================================

# --- layouts/auth.vue ---
cat > layouts/auth.vue << 'EOF'
<template>
  <div class="layout-auth">
    <div class="auth-container">
      <div class="auth-brand">
        <NuxtLink to="/"><h1>AI Reviewer 测试商城</h1></NuxtLink>
      </div>
      <slot />
    </div>
  </div>
</template>

<style scoped>
.layout-auth { min-height: 100vh; display: flex; justify-content: center; align-items: center; background: #f3f4f6; }
.auth-container { width: 100%; max-width: 480px; padding: 2rem; }
.auth-brand { text-align: center; margin-bottom: 2rem; }
</style>
EOF

# ============================================================================
# App entry
# ============================================================================

cat > app.vue << 'EOF'
<template>
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
</template>

<script setup lang="ts">
useHead({
  titleTemplate: '%s - AI Reviewer Test',
  htmlAttrs: { lang: 'zh-CN' }
})
</script>
EOF

# ============================================================================
# Assets
# ============================================================================

cat > assets/css/main.css << 'EOF'
:root {
  --color-primary: #3b82f6;
  --color-danger: #ef4444;
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-text: #1f2937;
  --color-text-light: #6b7280;
  --color-border: #e5e7eb;
  --color-bg: #ffffff;
  --color-bg-secondary: #f9fafb;
}

* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  color: var(--color-text);
  background: var(--color-bg);
  line-height: 1.6;
}

a { color: var(--color-primary); text-decoration: none; }
EOF

# ============================================================================
# CodeSentinel 配置文件
# ============================================================================

cat > .codesentinel.yaml << 'EOF'
language: "zh-CN"

path_filters:
  - "!node_modules/**"
  - "!.nuxt/**"
  - "!dist/**"
  - "!*.lock"
  - "components/**"
  - "composables/**"
  - "pages/**"
  - "server/**"
  - "stores/**"
  - "utils/**"
  - "base-layer/**"

max_files: 50
max_review_comments: 20

enable_dependency_analysis: true
max_dependency_files: 10

enable_lint_tools: true
enable_eslint: true

enable_web_search: true
enable_shell: true
EOF

# ============================================================================
echo ""
echo "✅ 基线项目生成完成！"
echo ""
echo "📋 下一步操作："
echo "  1. git add -A"
echo "  2. git commit -m 'feat: add nuxt.js test project baseline'"
echo "  3. git push origin main"
echo "  4. 然后切到 feature 分支执行 docs/generate-issues.sh"
