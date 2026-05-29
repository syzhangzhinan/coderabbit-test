<script setup lang="ts">
/**
 * 购物车摘要组件
 *
 * 测试场景 1: 显式导入 composables/useAuth.ts
 * 测试场景 2: auto-import composables/useCart.ts
 * 测试场景 3: auto-import utils/formatPrice.ts
 * 测试场景 4: 显式导入 components/ui/BaseButton.vue
 */
import BaseButton from '~/components/ui/BaseButton.vue'
import { useAuth } from '~/composables/useAuth'
import { formatPrice } from '~/utils/formatPrice'

const { items, total, removeItem } = useCart()
const { isLoggedIn } = useAuth()

const formattedTotal = computed(() => formatPrice(total.value))
</script>

<template>
  <div class="cart-summary">
    <div v-for="item in items" :key="item.id" class="cart-item">
      <span>{{ item.name }}</span>
      <span>{{ formatPrice(item.price) }} × {{ item.quantity }}</span>
      <BaseButton variant="danger" @click="removeItem(item.id)">
        删除
      </BaseButton>
    </div>
    <div class="cart-total">
      <strong>合计: {{ formattedTotal }}</strong>
    </div>
    <BaseButton v-if="isLoggedIn" variant="primary">
      结算
    </BaseButton>
    <p v-else>请先登录</p>
  </div>
</template>
