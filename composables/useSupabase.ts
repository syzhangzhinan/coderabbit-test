/**
 * Supabase 客户端 composable
 *
 * Web Search 测试场景 5: 使用第三方 SDK — 验证 Supabase API 用法
 * Web Search 测试场景 6: SDK 版本升级 — 验证 v1 → v2 API 变更
 */

import { createClient } from "@supabase/supabase-js"

const supabaseUrl = process.env.SUPABASE_URL || "https://example.supabase.co"
const supabaseKey = process.env.SUPABASE_ANON_KEY || "your-anon-key"

const supabase = createClient(supabaseUrl, supabaseKey)

// 场景 5: Supabase 查询 API — AI 应通过 web search 验证链式调用是否正确
// 修改点: 引入不存在的查询方法（如 .contains() 应为 .containedBy()）
export async function getProducts(category?: string) {
  let query = supabase.from("products").select("id, name, price, category")

  if (category) {
    query = query.eq("category", category)
  }

  const { data, error } = await query.order("created_at", { ascending: false })

  if (error) throw error
  return data
}

// 场景 6: Supabase Auth API — v1 语法 vs v2 语法
// 修改点: 使用 v1 的 signIn 方法（v2 已改为 signInWithPassword）
export async function loginUser(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({
    // const { data, error } = await supabase.auth.signIn({
    email,
    password
  })

  if (error) throw error
  return data.session
}

// 场景 6: Supabase Realtime — 验证订阅 API
export function subscribeToProducts(callback: (payload: unknown) => void) {
  return supabase
    .channel("products-changes")
    .on("postgres_changes", { event: "*", schema: "public", table: "products" }, callback)
    .subscribe()
}
