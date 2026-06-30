#!/bin/bash
# ============================================================================
# 测试组 06: AI 工具 - Web搜索与Shell执行
# ============================================================================
# 验证功能点:
#   - enable_web_search: true（AI 联网验证 API 用法）
#   - enable_shell: true（AI 执行 shell 命令辅助分析）
#   - Analysis chain 中有 web_search/shell 步骤
#   - enable_web_search: false 时无联网行为
#   - enable_shell: false 时无 shell 执行
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-06-ai-tools"
echo "🚀 [06] AI 工具测试（Web Search + Shell）"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 触发 Web Search: 使用冷门/复杂 API ---
cat > composables/useSupabase.ts << 'EOF'
import { createClient, type SupabaseClient } from '@supabase/supabase-js'

// 触发 web_search: Supabase SSR 用法是否正确？
// AI 应联网查询 @supabase/supabase-js v2 在 Nuxt3 SSR 环境下的正确用法
let instance: SupabaseClient | null = null

export const useSupabase = () => {
  const config = useRuntimeConfig()

  // 潜在问题：全局单例在 SSR 下跨请求共享状态
  // AI 需要联网确认这是否是反模式
  if (!instance) {
    instance = createClient(
      config.public.supabaseUrl as string,
      config.public.supabaseAnonKey as string,
      {
        auth: {
          // 触发 web_search: autoRefreshToken 在 SSR 下的行为
          autoRefreshToken: true,
          persistSession: true,
          // 触发 web_search: detectSessionInUrl 是否已废弃
          detectSessionInUrl: true
        }
      }
    )
  }

  // 触发 web_search: Supabase realtime 在 SSR 下能用吗？
  const subscribeToChanges = (table: string, callback: (payload: any) => void) => {
    return instance!
      .channel(`public:${table}`)
      .on('postgres_changes', { event: '*', schema: 'public', table }, callback)
      .subscribe()
  }

  return { client: instance!, subscribeToChanges }
}
EOF

# --- 触发 Shell: 依赖版本和配置检查 ---
cat > tsconfig.json << 'EOF'
{
  "extends": "./.nuxt/tsconfig.json",
  "compilerOptions": {
    "strict": true,
    "noEmit": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": true
  },
  "include": ["**/*.ts", "**/*.vue"],
  "exclude": ["node_modules", "dist"]
}
EOF

cat > eslint.config.js << 'EOF'
import globals from 'globals'

export default [
  {
    languageOptions: {
      globals: { ...globals.browser, ...globals.node }
    },
    rules: {
      'no-unused-vars': 'warn',
      'no-console': 'off',
      'eqeqeq': 'error'
    }
  }
]
EOF

# --- 触发 Web Search: 使用最新但文档易混淆的 API ---
cat > utils/api-client.ts << 'EOF'
// 触发 web_search: fetch API 的 signal + AbortController 在 Node.js 下的兼容性
export const createApiClient = (baseUrl: string) => {
  const controller = new AbortController()

  const request = async (path: string, options?: RequestInit) => {
    // 触发 web_search: Node.js fetch 是否支持 keepalive?
    const response = await fetch(`${baseUrl}${path}`, {
      ...options,
      signal: controller.signal,
      keepalive: true,
      // 触发 web_search: priority 是否为标准属性？
      priority: 'high' as any
    })

    if (!response.ok) {
      // 触发 web_search: Response.json() 在非 JSON 响应时的行为
      const error = await response.json()
      throw new Error(error.message)
    }

    return response.json()
  }

  return { request, abort: () => controller.abort() }
}
EOF

git add -A
git commit -m "test: AI tools - web search triggers (Supabase SSR, fetch API) + shell triggers"

echo ""
echo "✅ 代码已提交到 $BRANCH"
echo ""
echo "📋 下一步："
echo "  git push origin $BRANCH"
echo "  gh pr create --base main --head $BRANCH --title 'test: 06-AI工具(Web搜索+Shell)验证'"
echo ""
echo "🔍 验证清单："
echo "  □ AI 评论引用了联网查询结果（如 Supabase 文档）"
echo "  □ Analysis chain 中出现 web_search 步骤"
echo "  □ AI 可能执行 shell 检查 tsconfig/eslint 配置"
echo "  □ Analysis chain 中出现 shell 步骤"
echo "  □ [对比] enable_web_search: false 时无联网内容"
echo "  □ [对比] enable_shell: false 时无 shell 内容"
