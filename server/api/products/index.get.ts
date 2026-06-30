import type { Product } from '~/types'

const mockProducts: Product[] = [
  { id: '1', name: 'TypeScript 入门教程', price: 49.9, description: '从零开始学习 TypeScript', stock: 100, category: 'books', imageUrl: '/images/ts-book.png' },
  { id: '2', name: 'Vue.js 实战', price: 69.9, description: 'Vue 3 + Composition API 完整指南', stock: 50, category: 'books', imageUrl: '/images/vue-book.png' },
  { id: '3', name: '机械键盘', price: 299.0, description: '87键 Cherry MX 红轴', stock: 3, category: 'electronics', imageUrl: '/images/keyboard.png' }
]

export default defineEventHandler((event) => {
  const query = getQuery(event)
  const page = Math.max(1, Number(query.page) || 1)
  const pageSize = Math.min(100, Math.max(1, Number(query.pageSize) || 20))

  const start = (page - 1) * pageSize
  const data = mockProducts.slice(start, start + pageSize)

  return { data, totalPages: Math.ceil(mockProducts.length / pageSize) }
})
