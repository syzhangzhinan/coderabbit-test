#!/bin/bash
# ============================================================================
# 测试组 07: 命令系统
# ============================================================================
# 验证功能点:
#   - @codesentinel help（展示所有命令）
#   - @ai-reviewer help（别名触发）
#   - @codesentinel review（增量审查）
#   - @codesentinel full review（全量审查）
#   - @codesentinel summary（重新生成摘要）
#   - @codesentinel pause / resume（暂停/恢复审查）
#   - @codesentinel resolve（批量解决 Bot 评论）
#   - @codesentinel configuration（展示当前配置）
#   - command_ack_reaction: rocket（🚀 表情确认）
#   - 无效命令错误反馈
#   - 大小写不敏感
#   - Bot 自身评论不触发
#   - 速率限制
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-07-commands"
echo "🚀 [07] 命令系统测试"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 生成包含问题的代码（让 Bot 产出评论供 resolve 测试）---
cat > utils/command-test-trigger.ts << 'EOF'
// 此文件目的：让 Bot 产出多条行级评论，用于后续 resolve 命令测试

// 问题1: SQL 注入
export const searchProducts = (keyword: string) => {
  return `SELECT * FROM products WHERE name LIKE '%${keyword}%'`
}

// 问题2: 密码明文比较
export const checkPassword = (input: string, stored: string) => {
  return input === stored
}

// 问题3: Math.random 用作安全用途
export const generateSessionId = () => {
  return Math.random().toString(36).substring(2, 15)
}

// 问题4: 无错误处理
export const fetchData = async (url: string) => {
  const res = await fetch(url)
  return res.json()
}

// 问题5: 竞态条件
let balance = 1000
export const withdraw = async (amount: number) => {
  if (balance >= amount) {
    await new Promise(r => setTimeout(r, 100))
    balance -= amount
    return true
  }
  return false
}
EOF

git add -A
git commit -m "test: commands - trigger code for bot to produce review comments"

echo ""
echo "✅ 代码已提交到 $BRANCH"
echo ""
echo "📋 下一步："
echo "  git push origin $BRANCH"
echo "  gh pr create --base main --head $BRANCH --title 'test: 07-命令系统验证'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 命令测试脚本（在 PR 评论中按顺序执行）："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "== 第 1 步: 等待 Bot 首次自动审查完成 =="
echo ""
echo "== 第 2 步: 命令解析与路由 =="
echo "  评论: @codesentinel help"
echo "  验证: □ 展示所有命令用法"
echo "        □ 评论上出现 🚀 ACK 表情"
echo ""
echo "  评论: @ai-reviewer help"
echo "  验证: □ 别名同样触发"
echo ""
echo "  评论: @CodeSentinel HELP"
echo "  验证: □ 大小写不敏感"
echo ""
echo "  评论: @codesentinel invalidcommand"
echo "  验证: □ 回帖提示无效命令"
echo ""
echo "== 第 3 步: 配置与摘要 =="
echo "  评论: @codesentinel configuration"
echo "  验证: □ 展示当前配置表格"
echo ""
echo "  评论: @codesentinel summary"
echo "  验证: □ 重新生成 PR 摘要"
echo ""
echo "== 第 4 步: resolve 命令 =="
echo "  评论: @codesentinel resolve"
echo "  验证: □ 批量解决 Bot 评论"
echo "        □ 回帖统计: 成功 N 条"
echo ""
echo "== 第 5 步: 暂停/恢复 =="
echo "  评论: @codesentinel pause"
echo "  验证: □ PR 描述写入暂停标记"
echo ""
echo "  操作: push 新 commit（修改任一文件）"
echo "  验证: □ Bot 不自动触发审查"
echo ""
echo "  评论: @codesentinel resume"
echo "  验证: □ 恢复审查标记"
echo ""
echo "  操作: push 新 commit"
echo "  验证: □ Bot 重新触发审查"
echo ""
echo "== 第 6 步: review 命令 =="
echo "  评论: @codesentinel review"
echo "  验证: □ 触发增量审查"
echo ""
echo "  评论: @codesentinel full review"
echo "  验证: □ 从 base 全量审查"
echo ""
echo "== 第 7 步: 限流测试 =="
echo "  快速连续发送 5 次: @codesentinel help"
echo "  验证: □ 第 N 次被限流，提示重试时间"
echo ""
