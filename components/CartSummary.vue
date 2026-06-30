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
