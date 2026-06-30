interface ApiOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE'
  body?: unknown
  headers?: Record<string, string>
}

export const useApi = () => {
  const config = useRuntimeConfig()
  const baseURL = config.public.apiBase as string

  const request = async <T>(endpoint: string, options: ApiOptions = {}): Promise<T> => {
    const { method = 'GET', body, headers = {} } = options

    try {
      const response = await $fetch<T>(`${baseURL}${endpoint}`, {
        method,
        body,
        headers: {
          'Content-Type': 'application/json',
          ...headers
        }
      })
      return response
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Request failed'
      throw new Error(`API Error [${method} ${endpoint}]: ${message}`)
    }
  }

  return { request }
}
