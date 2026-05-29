<script setup lang="ts">
/**
 * 评价面板组件（被异步加载）
 *
 * 测试场景 9: 被 pages/dashboard.vue 通过 defineAsyncComponent 异步导入
 */

export interface Review {
  id: string
  author: string
  rating: number
  content: string
}

const props = defineProps<{
  reviews: Review[]
}>()

const averageRating = computed(() => {
  if (props.reviews.length === 0) return 0
  return props.reviews.reduce((sum, r) => sum + r.rating, 0) / props.reviews.length
})
</script>

<template>
  <div class="review-panel">
    <h3>用户评价 ({{ averageRating.toFixed(1) }})</h3>
    <div v-for="review in reviews" :key="review.id" class="review-item">
      <strong>{{ review.author }}</strong> — {{ '⭐'.repeat(review.rating) }}
      <p>{{ review.content }}</p>
    </div>
  </div>
</template>
