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
