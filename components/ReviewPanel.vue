<template>
  <div class="review-panel">
    <h3>商品评价</h3>
    <div v-if="reviews.length === 0" class="no-reviews">暂无评价</div>
    <div v-for="review in paginatedReviews" :key="review.id" class="review-item">
      <div class="review-header">
        <span class="reviewer">{{ review.userName }}</span>
        <span class="rating">{{ '⭐'.repeat(review.rating) }}</span>
        <span class="date">{{ formatDate(review.createdAt) }}</span>
      </div>
      <p class="review-content">{{ review.content }}</p>
    </div>
    <form @submit.prevent="submitReview" class="review-form">
      <textarea v-model="newReview" placeholder="写下你的评价..." rows="3" />
      <select v-model="newRating">
        <option :value="1">1星</option>
        <option :value="2">2星</option>
        <option :value="3">3星</option>
        <option :value="4">4星</option>
        <option :value="5">5星</option>
      </select>
      <BaseButton variant="primary" type="submit" :disabled="submitting">提交评价</BaseButton>
    </form>
  </div>
</template>

<script setup lang="ts">
interface Review {
  id: string
  userName: string
  rating: number
  content: string
  createdAt: string
}

const props = defineProps<{
  productId: string
}>()

const reviews = ref<Review[]>([])
const newReview = ref('')
const newRating = ref(5)
const submitting = ref(false)
const page = ref(1)
const pageSize = 10

const paginatedReviews = computed(() => {
  return reviews.value.slice(0, page.value * pageSize)
})

const fetchReviews = async () => {
  reviews.value = await $fetch<Review[]>(`/api/products/${props.productId}/reviews`)
}

const formatDate = (dateStr: string) => {
  return new Intl.DateTimeFormat('zh-CN').format(new Date(dateStr))
}

const submitReview = async () => {
  if (submitting.value || !newReview.value.trim()) return
  submitting.value = true
  try {
    await $fetch(`/api/products/${props.productId}/reviews`, {
      method: 'POST',
      body: { content: newReview.value, rating: newRating.value }
    })
    newReview.value = ''
    await fetchReviews()
  } finally {
    submitting.value = false
  }
}

onMounted(fetchReviews)
</script>

<style scoped>
.review-panel { margin-top: 2rem; }
.review-item { padding: 1rem 0; border-bottom: 1px solid #e5e7eb; }
.review-header { display: flex; gap: 1rem; align-items: center; margin-bottom: 0.5rem; }
.reviewer { font-weight: bold; }
.date { color: #6b7280; font-size: 0.875rem; }
.review-form { margin-top: 1rem; display: flex; flex-direction: column; gap: 0.5rem; }
</style>
