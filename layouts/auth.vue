<template>
  <div class="layout-auth">
    <div class="auth-container">
      <div class="auth-brand">
        <NuxtLink to="/"><h1>AI Reviewer 测试商城</h1></NuxtLink>
      </div>
      <slot />
    </div>
  </div>
</template>

<style scoped>
.layout-auth { min-height: 100vh; display: flex; justify-content: center; align-items: center; background: #f3f4f6; }
.auth-container { width: 100%; max-width: 480px; padding: 2rem; }
.auth-brand { text-align: center; margin-bottom: 2rem; }
</style>
