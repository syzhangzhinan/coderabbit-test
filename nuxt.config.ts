// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  devtools: { enabled: true },

  // Nuxt extends: 继承 base-layer 层的 composables、components、utils
  extends: ['./base-layer'],

  modules: ['@pinia/nuxt']
})
