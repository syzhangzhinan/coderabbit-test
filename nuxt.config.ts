export default defineNuxtConfig({
  extends: ['./base-layer'],

  modules: ['@pinia/nuxt', '@vueuse/nuxt'],

  runtimeConfig: {
    // 问题：敏感信息有硬编码默认值
    supabaseServiceKey: 'default-service-key',
    public: {
      apiBase: 'https://api.example.com',
      supabaseUrl: 'https://xxx.supabase.co',
      supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.placeholder'
    }
  },

  devtools: { enabled: true },

  typescript: {
    strict: true
  },

  compatibilityDate: '2024-11-01'
})
