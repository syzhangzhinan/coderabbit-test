<script setup lang="ts">
/**
 * 购物车页面
 *
 * 测试场景 2: auto-import useCart (Nuxt auto-import)
 */

// Nuxt auto-import
const { items, addItem, removeItem } = useCart()
</script>

<template>
  <div class="page-cart">
    <h1>购物车</h1>
    <CartSummary />
    <p v-if="items.length === 0">购物车为空</p>
  </div>
</template>
