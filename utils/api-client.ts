interface RequestConfig {
  baseURL?: string
  timeout?: number
  retries?: number
}

class ApiClient {
  private baseURL: string
  private timeout: number
  private retries: number

  constructor(config: RequestConfig = {}) {
    this.baseURL = config.baseURL || ''
    this.timeout = config.timeout || 30000
    this.retries = config.retries || 0
  }

  async get<T>(url: string, params?: Record<string, unknown>): Promise<T> {
    return this.request<T>('GET', url, { params })
  }

  async post<T>(url: string, body?: unknown): Promise<T> {
    return this.request<T>('POST', url, { body })
  }

  async put<T>(url: string, body?: unknown): Promise<T> {
    return this.request<T>('PUT', url, { body })
  }

  async delete<T>(url: string): Promise<T> {
    return this.request<T>('DELETE', url)
  }

  private isIdempotent(method: string): boolean {
    return ['GET', 'PUT', 'DELETE', 'HEAD', 'OPTIONS'].includes(method)
  }

  private async request<T>(method: string, url: string, options: Record<string, unknown> = {}): Promise<T> {
    let lastError: Error | null = null
    const maxAttempts = this.isIdempotent(method) ? this.retries + 1 : 1

    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        const response = await $fetch<T>(`${this.baseURL}${url}`, {
          method: method as any,
          ...options,
          timeout: this.timeout
        })
        return response
      } catch (error: unknown) {
        lastError = error instanceof Error ? error : new Error(String(error))
        if (attempt < maxAttempts - 1) {
          const delay = Math.min(1000 * Math.pow(2, attempt), 10000)
          await new Promise(resolve => setTimeout(resolve, delay))
        }
      }
    }

    throw lastError
  }
}

export const apiClient = new ApiClient({
  baseURL: '/api',
  retries: 3,
  timeout: 10000
})
