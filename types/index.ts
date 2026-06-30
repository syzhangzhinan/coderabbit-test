export interface User {
  id: string
  email: string
  name: string
  role: 'admin' | 'user' | 'guest'
  createdAt: string
}

export interface Product {
  id: string
  name: string
  price: number
  description: string
  stock: number
  category: string
  imageUrl: string
}

export interface CartItem {
  product: Product
  quantity: number
}

export interface Order {
  id: string
  userId: string
  items: CartItem[]
  total: number
  status: 'pending' | 'paid' | 'shipped' | 'completed'
  createdAt: string
}

export interface ApiResponse<T> {
  data: T
  error?: string
  meta?: {
    total: number
    page: number
    pageSize: number
  }
}
