<script setup lang="ts">
/**
 * 商品详情页
 *
 * 测试场景 3: 引用 utils/formatPrice.ts
 */
import { formatPrice } from '~/utils/formatPrice'

const route = useRoute()
const productId = route.params.id as string

// 模拟商品数据
const product = ref({
  id: productId,
  name: `商品 ${productId}`,
  price: 99.99,
  description: '这是一个测试商品'
})

const formattedPrice = computed(() => formatPrice(product.value.price))
</script>

<template>
  <div class="page-product-detail">
    <h1>{{ product.name }}</h1>
    <p class="price">{{ formattedPrice }}</p>
    <p>{{ product.description }}</p>
  </div>
</template>
