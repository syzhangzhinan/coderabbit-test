#!/bin/bash
# ============================================================================
# 测试组 10: 国际化与 Bot 身份
# ============================================================================
# 验证功能点:
#   - language: zh-CN（所有评论/摘要用中文输出）
#   - bot_icon: 🦉（Bot 评论中的图标）
#   - bot_name: CodeSentinel（评论中的名称）
#   - bot_github_login（Bot 识别用于 resolve）
#   - 严重级别中文标签
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-10-i18n"
echo "🚀 [10] 国际化与 Bot 身份测试"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 包含各种问题的代码（验证输出语言）---
cat > utils/i18n-test.ts << 'EOF'
// 此文件让 Bot 产出评论，用于验证输出是否为中文

// 安全问题（应产出中文 critical 评论）
export const login = (user: string, pass: string) => {
  // 硬编码凭据
  if (user === 'admin' && pass === 'admin123') {
    return { token: 'fake-token' }
  }
  return null
}

// 性能问题（应产出中文 major 评论）
export const slowSearch = (items: any[], query: string) => {
  return items.filter(item => {
    return JSON.stringify(item).includes(query)
  })
}

// 逻辑问题（应产出中文 minor 评论）
export const divide = (a: number, b: number) => {
  return a / b  // 未处理除零
}
EOF

git add -A
git commit -m "test: i18n - verify Chinese output and bot identity"

echo ""
echo "✅ 代码已提交到 $BRANCH"
echo ""
echo "📋 下一步："
echo "  git push origin $BRANCH"
echo "  gh pr create --base main --head $BRANCH --title 'test: 10-国际化与Bot身份验证'"
echo ""
echo "🔍 验证清单："
echo "  □ PR 摘要评论为中文（Walkthrough/Changes 内容中文）"
echo "  □ 行级评论为中文描述"
echo "  □ 严重级别使用中文标签（如 🚨 严重 / ⚠️ 重要 / 💡 建议）"
echo "  □ 评论中含 Bot 名称 'CodeSentinel'"
echo "  □ 评论中含 Bot 图标 🦉"
echo "  □ Release Notes 为中文"
echo "  □ help 命令输出为中文"
