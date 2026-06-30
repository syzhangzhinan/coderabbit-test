<template>
  <div class="product-card" @click="goToProduct">
    <img :src="product.imageUrl" :alt="product.name" class="product-image" />
    <div class="product-info">
      <h3>{{ product.name }}</h3>
      <p class="price">{{ formattedPrice }}</p>
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
import { formatPrice } from '~/utils/formatPrice'

const props = defineProps<{
  product: Product
}>()

const { addToCart } = useCart()
const router = useRouter()

const formattedPrice = computed(() => formatPrice(props.product.price))

const goToProduct = () => {
  router.push(`/products/${props.product.id}`)
}

const handleAddToCart = () => {
  if (props.product.stock > 0) {
    addToCart(props.product)
  }
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
.product-card:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}
.product-image {
  width: 100%;
  height: 200px;
  object-fit: cover;
}
.product-info {
  padding: 1rem;
}
.price {
  color: #ef4444;
  font-size: 1.25rem;
  font-weight: bold;
}
.low-stock {
  color: #f59e0b;
}
</style>
