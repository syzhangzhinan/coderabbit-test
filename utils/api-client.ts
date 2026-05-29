/**
 * API 客户端工具
 *
 * Web Search 测试场景 1: 使用外部库 API — 引入已废弃的 axios 用法
 * Web Search 测试场景 2: 使用 fetch API — 验证 Request/Response 接口
 */

import axios from "axios"

// 场景 1: 使用 axios — AI 应通过 web search 验证 API 用法
// 修改点: 将 axios.get 改为已废弃的 axios({ method: 'get', ... }) 写法
// 或引入不存在的 config 属性
export async function fetchProducts(categoryId: string) {
  const response = await axios.get("/api/products", {
    params: { category: categoryId },
    timeout: 5000
  })
  return response.data
}

// 场景 2: 使用 Fetch API — AI 应验证 AbortSignal.timeout 的浏览器兼容性
export async function fetchWithTimeout(url: string, timeoutMs = 5000) {
  const response = await fetch(url, {
    // signal: AbortSignal.timeout(timeoutMs)
    signal: AbortSignal.any([AbortSignal.timeout(timeoutMs), new AbortController().signal])
  })
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`)
  }
  return response.json()
}
