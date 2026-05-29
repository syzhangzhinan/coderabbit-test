<script setup lang="ts">
/**
 * 默认布局
 *
 * 测试场景 6: auto-import base-layer composable useTheme
 * 测试场景 7: 使用 base-layer component AppHeader
 */

// auto-import from base-layer
const { isDark, toggleTheme } = useTheme()
</script>

<template>
  <div class="layout-default" :class="{ dark: isDark }">
    <AppHeader />
    <main>
      <slot />
    </main>
    <footer>
      <button @click="toggleTheme">切换主题</button>
    </footer>
  </div>
</template>
