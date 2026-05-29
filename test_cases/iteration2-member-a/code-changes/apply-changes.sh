#!/usr/bin/env bash
#
# apply-changes.sh — 一键应用迭代二测试用代码改动
#
# 用法:
#   cd ai-reviewer-test
#   bash test_cases/iteration2-member-a/code-changes/apply-changes.sh
#
# 做什么:
#   1. 创建测试分支 test/iter2-cmd-framework
#   2. 修改 utils/validators.ts（追加 isValidUrl + isStrongPassword）
#   3. 替换 composables/useAuth.ts（修改签名 + 引入 async 问题）
#   4. 修改 utils/formatPrice.ts（默认货币 CNY → USD）
#   5. 新建 utils/command-test-marker.ts
#   6. 提交代码
#   7. 推送并创建 PR
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

cd "$REPO_ROOT"
echo "工作目录: $(pwd)"

# 1. 创建分支
BRANCH="test/iter2-cmd-framework"
echo "==> 创建分支 ${BRANCH}"
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# 2. utils/validators.ts — 追加代码
echo "==> 修改 utils/validators.ts"
cat >> utils/validators.ts << 'TS'

/**
 * 校验 URL 格式
 * 迭代二命令框架测试 — 故意引入 ReDoS 风险
 */
export function isValidUrl(url: string): boolean {
  // 注意: 这个正则存在 ReDoS 风险（嵌套量词）
  const urlRegex = /^(https?:\/\/)?([\w-]+\.)+[\w-]+(\/[\w-./?%&=]*)*$/
  return urlRegex.test(url)
}

/**
 * 校验密码强度
 * 要求: 至少 8 位，包含大小写字母和数字
 */
export function isStrongPassword(password: string): boolean {
  if (password.length < 8) return false
  const hasUpper = /[A-Z]/.test(password)
  const hasLower = /[a-z]/.test(password)
  const hasDigit = /\d/.test(password)
  return hasUpper && hasLower && hasDigit
}
TS

# 3. composables/useAuth.ts — 全文替换
echo "==> 替换 composables/useAuth.ts"
cp "$SCRIPT_DIR/useAuth.ts.new" composables/useAuth.ts

# 4. utils/formatPrice.ts — sed 替换
echo "==> 修改 utils/formatPrice.ts"
if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' 's/currency: string = "CNY"/currency: string = "USD"/' utils/formatPrice.ts
else
  sed -i 's/currency: string = "CNY"/currency: string = "USD"/' utils/formatPrice.ts
fi

# 5. 新建标记文件
echo "==> 创建 utils/command-test-marker.ts"
cp "$SCRIPT_DIR/command-test-marker.ts" utils/command-test-marker.ts

# 6. 提交
echo "==> 提交代码"
git add \
  utils/validators.ts \
  composables/useAuth.ts \
  utils/formatPrice.ts \
  utils/command-test-marker.ts
git commit -m "test: iter2 command framework — code changes for review

改动内容:
- utils/validators.ts: 新增 isValidUrl (ReDoS) + isStrongPassword
- composables/useAuth.ts: 修改签名 + 未 await async
- utils/formatPrice.ts: 默认货币 CNY → USD
- utils/command-test-marker.ts: 测试标记文件"

# 7. 推送 + 创建 PR
echo "==> 推送到远程"
git push -u origin "$BRANCH"

echo "==> 创建 PR"
PR_URL=$(gh pr create \
  --title "[TEST] 迭代二 · 命令框架端到端验证" \
  --body "$(cat << 'EOF'
## 目的

验证 ai-reviewer 迭代二 · 成员 A 命令框架功能。

## 代码改动

1. `utils/validators.ts` — 新增 `isValidUrl`（故意 ReDoS）+ `isStrongPassword`
2. `composables/useAuth.ts` — 修改签名 + 未 await async
3. `utils/formatPrice.ts` — 默认货币 CNY → USD
4. `utils/command-test-marker.ts` — 测试标记文件

## 测试方法

按 `docs/05-iteration2-command-framework-test.md` 中的场景逐条在评论区发送命令。
EOF
)")

PR_NUM=$(echo "$PR_URL" | grep -oE '[0-9]+$')
echo ""
echo "============================================="
echo "  PR 已创建: ${PR_URL}"
echo "  PR 编号:   #${PR_NUM}"
echo "============================================="
echo ""
echo "下一步:"
echo "  1. 等待自动 review 完成（约 1~3 分钟）"
echo "  2. 运行测试脚本:"
echo "     PR=${PR_NUM} bash docs/run-iter2-test.sh"
echo "  3. 或 DRY RUN 预览:"
echo "     DRY=1 PR=${PR_NUM} bash docs/run-iter2-test.sh"
