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
