<script setup lang="ts">
/**
 * 首页
 *
 * 测试场景 1: auto-import useAuth (Nuxt auto-import)
 */

// Nuxt auto-import — 无需显式 import
const { isLoggedIn, login, logout } = useAuth()

const email = ref('')
const password = ref('')

async function handleLogin() {
  await login(email.value, password.value)
}
</script>

<template>
  <div class="page-home">
    <h1>AI Reviewer Test — Nuxt 项目</h1>

    <div v-if="isLoggedIn">
      <p>已登录</p>
      <button @click="logout">退出</button>
    </div>
    <div v-else>
      <input v-model="email" placeholder="Email" />
      <input v-model="password" type="password" placeholder="Password" />
      <button @click="handleLogin">登录</button>
    </div>

    <NuxtLink to="/cart">查看购物车</NuxtLink>
  </div>
</template>
