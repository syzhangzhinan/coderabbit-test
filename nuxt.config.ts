export default defineNuxtConfig({
  extends: ['./base-layer'],

  modules: ['@pinia/nuxt', '@vueuse/nuxt'],

  runtimeConfig: {
    supabaseServiceKey: '',
    public: {
      apiBase: '',
      supabaseUrl: '',
      supabaseAnonKey: ''
    }
  },

  devtools: { enabled: true },

  typescript: {
    strict: true
  },

  compatibilityDate: '2024-11-01'
})
