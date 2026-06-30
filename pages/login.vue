<template>
  <div class="login-page">
    <form class="login-form" @submit.prevent="handleLogin">
      <h2>登录</h2>
      <BaseInput v-model="email" label="邮箱" type="email" placeholder="请输入邮箱" :error="errors.email" />
      <BaseInput v-model="password" label="密码" type="password" placeholder="请输入密码" :error="errors.password" />
      <BaseButton variant="primary" type="submit" :loading="loading">登录</BaseButton>
      <p class="register-link">没有账号？<NuxtLink to="/register">去注册</NuxtLink></p>
    </form>
  </div>
</template>

<script setup lang="ts">
import { validators } from '~/base-layer/utils/validators'

definePageMeta({ layout: 'auth' })

const { login, loading } = useAuth()
const email = ref('')
const password = ref('')
const errors = reactive({ email: '', password: '' })

const handleLogin = async () => {
  errors.email = ''
  errors.password = ''

  if (!validators.isEmail(email.value)) {
    errors.email = '请输入有效的邮箱地址'
    return
  }
  if (!password.value || password.value.length < 6) {
    errors.password = '密码至少 6 个字符'
    return
  }

  try {
    await login(email.value, password.value)
    navigateTo('/dashboard')
  } catch {
    errors.email = '登录失败，请检查邮箱和密码'
  }
}
</script>

<style scoped>
.login-page { display: flex; justify-content: center; align-items: center; min-height: 80vh; }
.login-form { width: 100%; max-width: 400px; padding: 2rem; border: 1px solid #e5e7eb; border-radius: 8px; }
.register-link { text-align: center; margin-top: 1rem; }
</style>
