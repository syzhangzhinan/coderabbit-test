#!/bin/bash
# ============================================================================
# 测试组 08: 对话式追问交互
# ============================================================================
# 验证功能点:
#   - @codesentinel <问题>（在行级评论中追问）
#   - Bot 回复引用该行代码上下文
#   - 续轮追问包含历史对话
#   - 不带 @bot 的普通回复不触发
#   - Bot 自身回帖不自触发（无无限循环）
#   - 连续追问达到 10 轮后提示上限
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-08-conversation"
echo "🚀 [08] 对话追问测试"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 产出有深度可追问的代码 ---
cat > utils/date-helper.ts << 'EOF'
// 此文件的目的是让 Bot 产出行级评论后，在评论 thread 中追问

// 复杂的日期处理逻辑（适合追问"为什么这样不好"）
export const getRelativeTime = (date: Date): string => {
  const now = new Date()
  const diff = now.getTime() - date.getTime()

  // 问题：没有考虑时区和 DST
  const seconds = Math.floor(diff / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)

  if (days > 0) return `${days}天前`
  if (hours > 0) return `${hours}小时前`
  if (minutes > 0) return `${minutes}分钟前`
  return '刚刚'
}

// 问题：硬编码中国时区，无国际化
export const formatOrderDate = (isoString: string): string => {
  const date = new Date(isoString)
  return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()} ${date.getHours()}:${date.getMinutes()}`
}

// 问题：月份天数计算不准确
export const getDaysInMonth = (year: number, month: number): number => {
  // 没有处理闰年特殊情况
  const daysPerMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  return daysPerMonth[month]
}

// 问题：日期比较使用字符串比较
export const isDateBefore = (a: string, b: string): boolean => {
  return a < b
}

// 复杂业务逻辑（适合追问"怎么改"）
export const calculateBusinessDays = (start: Date, end: Date): number => {
  let count = 0
  const current = new Date(start)
  while (current <= end) {
    const day = current.getDay()
    if (day !== 0 && day !== 6) {
      count++
    }
    current.setDate(current.getDate() + 1)
  }
  return count
}
EOF

# 更复杂的架构问题文件（适合追问架构层面的问题）
cat > middleware/admin.ts << 'EOF'
// 问题：前端权限检查不可靠（可被绕过）
// 适合追问"前端权限校验有什么风险"
export default defineNuxtRouteMiddleware((to) => {
  const { user } = useAuth()

  // 问题1: 仅前端检查，无后端验证
  if (to.path.startsWith('/admin')) {
    if (!user.value || user.value.role !== 'admin') {
      return navigateTo('/login')
    }
  }

  // 问题2: 角色硬编码
  const adminPaths = ['/admin', '/dashboard/settings', '/users/manage']
  const requiresAdmin = adminPaths.some(p => to.path.startsWith(p))

  if (requiresAdmin && user.value?.role !== 'admin') {
    return navigateTo('/')
  }
})
EOF

git add -A
git commit -m "test: conversation - deep logic for follow-up questions in review threads"

echo ""
echo "✅ 代码已提交到 $BRANCH"
echo ""
echo "📋 下一步："
echo "  git push origin $BRANCH"
echo "  gh pr create --base main --head $BRANCH --title 'test: 08-对话追问交互验证'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 对话追问测试脚本（Bot 产出行级评论后执行）："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "== 第 1 步: 等待 Bot 产出行级评论 =="
echo ""
echo "== 第 2 步: 基础追问（在 Bot 的某条行级评论 thread 中）=="
echo "  回复: @codesentinel 为什么这样写不好？"
echo "  验证: □ Bot 回复解释原因"
echo "        □ 回复引用该行代码上下文"
echo ""
echo "== 第 3 步: 续轮追问 =="
echo "  回复: @codesentinel 那应该怎么改？给个代码示例"
echo "  验证: □ Bot 回复包含修改建议和代码"
echo "        □ 回复引用之前的对话上下文"
echo ""
echo "== 第 4 步: 不触发验证 =="
echo "  回复: 好的我知道了（不带 @bot）"
echo "  验证: □ Bot 不回复"
echo ""
echo "== 第 5 步: 跨行追问 =="
echo "  在 date-helper.ts 的评论中回复:"
echo "  @codesentinel 这整个日期处理模块应该怎么重构？"
echo "  验证: □ Bot 回复能感知文件整体变更"
echo ""
echo "== 第 6 步: [可选] 轮次上限测试 =="
echo "  在同一 thread 连续追问 10+ 轮"
echo "  验证: □ 第 11 轮提示轮次已达上限"
echo ""
