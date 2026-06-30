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
