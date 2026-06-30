import { defineStore } from 'pinia'
import type { Product } from '~/types'

export const useProductStore = defineStore('products', {
  state: () => ({
    products: [] as Product[],
    loading: false,
    currentPage: 1,
    totalPages: 0,
    searchQuery: '',
    selectedCategory: ''
  }),

  getters: {
    filteredProducts(): Product[] {
      let result = this.products
      if (this.searchQuery) {
        const query = this.searchQuery.toLowerCase()
        result = result.filter(p =>
          p.name.toLowerCase().includes(query) || p.description.toLowerCase().includes(query)
        )
      }
      if (this.selectedCategory) {
        result = result.filter(p => p.category === this.selectedCategory)
      }
      return result
    }
  },

  actions: {
    async fetchProducts(page: number = 1) {
      this.loading = true
      try {
        const response = await $fetch<{ data: Product[]; totalPages: number }>('/api/products', {
          params: { page, pageSize: 20 }
        })
        this.products = response.data
        this.totalPages = response.totalPages
        this.currentPage = page
      } finally {
        this.loading = false
      }
    },

    async deleteProduct(id: string) {
      await $fetch(`/api/products/${id}`, { method: 'DELETE' })
      this.products = this.products.filter(p => p.id !== id)
    }
  }
})
