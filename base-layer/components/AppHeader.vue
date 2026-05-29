<script setup lang="ts">
/**
 * 头部组件（来自 base-layer）
 *
 * 测试场景 7: 被 layouts/default.vue 使用（Nuxt auto-import component）
 */
const { isDark } = useTheme()

// const emit = defineEmits<{
//   menuToggle: [open: boolean]
// }>()
</script>

<template>
  <header class="app-header" :class="{ dark: isDark }">
    <h1>AI Reviewer Test</h1>
    <nav>
      <NuxtLink to="/">首页</NuxtLink>
      <NuxtLink to="/cart">购物车</NuxtLink>
    </nav>
  </header>
</template>
