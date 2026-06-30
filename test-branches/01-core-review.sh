#!/bin/bash
# ============================================================================
# 测试组 01: 核心审查流程
# ============================================================================
# 验证功能点:
#   - PR 自动审查触发（新建 PR 时 Bot 自动产出审查）
#   - PR 摘要评论格式（Walkthrough + Changes 表格）
#   - 行级评论定位准确
#   - Release Notes 生成（PR 描述末尾 "Summary by CodeSentinel"）
#   - disable_review: true（仅摘要无行级评论）
#   - disable_release_notes: true（不生成 Release Notes）
#   - review_simple_changes: false（trivial 变更被 triage 跳过）
#   - review_comment_lgtm: false（无问题时不留评论）
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-01-core-review"
echo "🚀 [01] 核心审查流程测试"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 测试文件 1: 包含明显问题的代码（触发行级评论）---
cat > utils/payment-processor.ts << 'EOF'
import { formatPrice } from './formatPrice'

interface PaymentRequest {
  amount: number
  cardNumber: string
  cvv: string
  userId: string
}

// 问题1: 信用卡号明文日志
// 问题2: 没有输入验证
// 问题3: 硬编码 API 密钥
export const processPayment = async (request: PaymentRequest) => {
  console.log(`Processing payment: card=${request.cardNumber}, cvv=${request.cvv}`)

  const API_KEY = 'HARDCODED_FALLBACK_KEY'

  const response = await fetch('https://api.stripe.com/v1/charges', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: `amount=${request.amount}&currency=cny&source=${request.cardNumber}`
  })

  // 问题4: 没有错误处理
  const result = await response.json()
  return result
}

// 问题5: SQL 注入
export const getOrderHistory = async (userId: string) => {
  const query = `SELECT * FROM orders WHERE user_id = '${userId}' ORDER BY created_at DESC`
  console.log('Executing query:', query)
  return []
}

// 问题6: 竞态条件 - 非原子性库存扣减
export const deductStock = async (productId: string, quantity: number) => {
  const current = await getStock(productId)
  if (current >= quantity) {
    await setStock(productId, current - quantity)
    return true
  }
  return false
}

const getStock = async (_id: string) => 100
const setStock = async (_id: string, _qty: number) => {}
EOF

# --- 测试文件 2: 完全正确的代码（验证 review_comment_lgtm: false 时不留评论）---
cat > utils/string-helpers.ts << 'EOF'
export const capitalize = (str: string): string => {
  if (!str) return ''
  return str.charAt(0).toUpperCase() + str.slice(1)
}

export const truncate = (str: string, maxLength: number): string => {
  if (str.length <= maxLength) return str
  return str.slice(0, maxLength - 3) + '...'
}

export const slugify = (str: string): string => {
  return str
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '')
}
EOF

# --- 测试文件 3: trivial 变更（验证 review_simple_changes: false 被跳过）---
cat > types/constants.ts << 'EOF'
export const APP_NAME = 'AI Reviewer Test Store'
export const APP_VERSION = '1.2.0'
export const DEFAULT_PAGE_SIZE = 20
export const MAX_CART_ITEMS = 99
export const SUPPORTED_LANGUAGES = ['zh-CN', 'en-US', 'ja-JP']
export const ORDER_STATUS = ['pending', 'paid', 'shipped', 'completed'] as const
EOF

git add -A
git commit -m "test: core review - security issues + trivial changes + clean code"

echo ""
echo "✅ 代码已提交到 $BRANCH"
echo ""
echo "📋 下一步："
echo "  git push origin $BRANCH"
echo "  gh pr create --base main --head $BRANCH --title 'test: 01-核心审查流程验证'"
echo ""
echo "🔍 验证清单："
echo "  □ Bot 自动产出 PR 摘要评论"
echo "  □ 摘要含 Walkthrough（高级概述）+ Changes（文件变更表格）"
echo "  □ payment-processor.ts 产出行级评论（安全/逻辑问题）"
echo "  □ 行级评论定位到正确代码行"
echo "  □ PR 描述末尾有 Release Notes（Summary by CodeSentinel）"
echo "  □ string-helpers.ts 无行级评论（review_comment_lgtm: false）"
echo "  □ types/constants.ts 被 triage 为 APPROVED（review_simple_changes: false）"
