<script setup lang="ts">
/**
 * 产品卡片组件
 *
 * 测试场景 3: 引用 utils/formatPrice.ts
 * 测试场景 4: 引用 components/ui/BaseButton.vue
 * 测试场景 6: 使用 base-layer composable useTheme
 */
import BaseButton from "~/components/ui/BaseButton.vue"
import { formatPrice } from "~/utils/formatPrice"

const props = defineProps<{
  id: string
  name: string
  price: number
  image: string
  badge?: string
}>()

// auto-import from base-layer composables
const { isDark } = useTheme()

const { addItem } = useCart()

const formattedPrice = computed(() => formatPrice(props.price))

function handleAddToCart() {
  addItem({ id: props.id, name: props.name, price: props.price })
}
</script>

<template>
  <div class="product-card" :class="{ dark: isDark }">
    <img :src="image" :alt="name" />
    <h3>{{ name }}</h3>
    <p class="price">{{ formattedPrice }}</p>
    <BaseButton @click="handleAddToCart">加入购物车</BaseButton>
  </div>
</template>
