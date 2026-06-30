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
