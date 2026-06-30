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
