<template>
  <header class="app-header">
    <nav>
      <NuxtLink to="/">首页</NuxtLink>
      <NuxtLink to="/products">商品</NuxtLink>
      <NuxtLink to="/cart">购物车</NuxtLink>
      <NuxtLink to="/dashboard">仪表盘</NuxtLink>
    </nav>
    <div class="user-actions">
      <span v-if="user">{{ user.name }}</span>
      <button @click="handleLogout">退出</button>
    </div>
  </header>
</template>

<script setup lang="ts">
const { user, logout } = useAuth()

const handleLogout = async () => {
  await logout()
  await navigateTo('/login')
}
</script>
