#!/bin/bash
# ============================================================================
# 测试组 09: 增量审查 - Step 2
# ============================================================================
# 前提：09-incremental.sh 已执行，PR 已创建，Bot 已完成首次审查
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-09-incremental"
echo "🚀 [09] 增量审查测试 - Step 2"

git checkout "$BRANCH"

# --- 第二次提交：新增问题代码（仅此部分应被增量审查）---
cat > utils/incremental-new.ts << 'EOF'
// 第二次提交的新文件（增量审查应只覆盖这个文件）

// 新问题: SSRF
export const fetchExternal = async (url: string) => {
  return await fetch(url).then(r => r.json())
}

// 新问题: 原型污染
export const deepSet = (obj: any, path: string, value: any) => {
  const keys = path.split('.')
  let current = obj
  for (let i = 0; i < keys.length - 1; i++) {
    if (!current[keys[i]]) current[keys[i]] = {}
    current = current[keys[i]]
  }
  current[keys[keys.length - 1]] = value
}
EOF

# 修改已有文件（添加新函数）
cat >> utils/incremental-base.ts << 'EOF'

// 新增函数（增量审查应覆盖此处）
// 问题: 命令注入
import { execSync } from 'child_process'
export const ping = (host: string) => execSync(`ping -c 1 ${host}`).toString()
EOF

git add -A
git commit -m "test: incremental review step 2 - new issues for delta review"

echo ""
echo "✅ Step 2 已提交"
echo ""
echo "📋 操作步骤："
echo "  1. git push origin $BRANCH"
echo "  2. 等待 Bot 增量审查（或执行 @codesentinel review）"
echo ""
echo "🔍 验证清单："
echo "  □ Bot 仅审查 incremental-new.ts + incremental-base.ts 的新增部分"
echo "  □ 不重复评论 Step 1 的 eval / SQL 注入"
echo "  □ 摘要中记录 commit 范围（上次审查 SHA → 本次 HEAD）"
echo "  □ 执行 @codesentinel full review 后从 base 全量审查"
