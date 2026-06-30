#!/bin/bash
# ============================================================================
# 测试组 09: 增量审查
# ============================================================================
# 验证功能点:
#   - 首次审查后 push 新 commit → 仅审查新增变更
#   - 摘要评论中记录已审查 commit（隐藏标签含 commit ID）
#   - @codesentinel review（触发增量审查）
#   - @codesentinel full review（从 base 到 HEAD 全量审查）
#   - 不重复审查旧代码
# ============================================================================
#
# ⚠️ 此测试需要分两次提交：
#   第一次：运行此脚本，push + 创建 PR，等待 Bot 完成首次审查
#   第二次：运行 09-incremental-step2.sh，push 新 commit，验证增量
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-09-incremental"
echo "🚀 [09] 增量审查测试 - Step 1"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 第一次提交：初始问题代码 ---
cat > utils/incremental-base.ts << 'EOF'
// 第一次提交的文件（Bot 首次审查会覆盖这里的问题）

// 问题: eval
export const evaluate = (expr: string) => eval(expr)

// 问题: SQL 注入
export const findById = (id: string) => `SELECT * FROM items WHERE id = '${id}'`

// 正确代码（不应产出评论）
export const safeAdd = (a: number, b: number): number => a + b
EOF

git add -A
git commit -m "test: incremental review step 1 - initial code with issues"

echo ""
echo "✅ Step 1 已提交到 $BRANCH"
echo ""
echo "📋 操作步骤："
echo "  1. git push origin $BRANCH"
echo "  2. gh pr create --base main --head $BRANCH --title 'test: 09-增量审查验证'"
echo "  3. 等待 Bot 完成首次审查"
echo "  4. 确认首次审查覆盖了 eval + SQL 注入"
echo "  5. 运行 ./test-branches/09-incremental-step2.sh 进行第二步"
echo ""
