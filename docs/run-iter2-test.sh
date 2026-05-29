#!/usr/bin/env bash
#
# 迭代二 · 命令框架端到端测试脚本
#
# 用法:
#   PR=123 bash docs/run-iter2-test.sh          # 实际发送评论
#   DRY=1 PR=123 bash docs/run-iter2-test.sh    # 仅打印不发送
#   PR=123 WAIT=60 bash docs/run-iter2-test.sh  # 自定义等待时间
#
# 前置条件:
#   - gh CLI 已登录
#   - 当前目录在 ai-reviewer-test 仓库内
#   - PR 已创建且 workflow 已配置 issue_comment 触发器
#

set -euo pipefail
: "${PR:?请设置 PR 编号: PR=123 bash $0}"
DRY="${DRY:-0}"
WAIT="${WAIT:-35}"

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "unknown")
echo "============================================="
echo "  迭代二 · 命令框架端到端测试"
echo "  仓库: ${REPO}"
echo "  PR:   #${PR}"
echo "  等待: ${WAIT}s / 条"
echo "  模式: $( [[ "$DRY" == "1" ]] && echo 'DRY RUN（不发送）' || echo '实际发送' )"
echo "============================================="
echo ""

PASS=0
TOTAL=0

post() {
  local label="$1"; shift
  local body="$*"
  TOTAL=$((TOTAL + 1))
  printf "[%s] %s\n" "$label" "$body"
  if [[ "$DRY" == "1" ]]; then
    PASS=$((PASS + 1))
    return
  fi
  if gh pr comment "$PR" --body "$body" >/dev/null 2>&1; then
    PASS=$((PASS + 1))
    echo "  ✓ 评论已发送，等待 ${WAIT}s ..."
    sleep "$WAIT"
  else
    echo "  ✗ 发送失败"
  fi
}

echo "--- 场景 1: help 基本可用性 ---"
post "1.1 help"          "@ai-reviewer help"
post "1.2 alias"         "@codesentinel help"
post "1.3 case"          "@AI-Reviewer HELP"

echo ""
echo "--- 场景 2: 复合命令 ---"
post "2   full review"   "@ai-reviewer full review"

echo ""
echo "--- 场景 3: stub 命令 NOT_IMPLEMENTED ---"
post "3a  review"        "@ai-reviewer review"
post "3c  resolve"       "@ai-reviewer resolve"
post "3d  summary"       "@ai-reviewer summary"
post "3e  pause"         "@ai-reviewer pause"
post "3f  resume"        "@ai-reviewer resume"
post "3g  configuration" "@ai-reviewer configuration"

echo ""
echo "--- 场景 4: 参数 kv ---"
post "4   kv args"       "@ai-reviewer review files=utils/validators.ts"

echo ""
echo "--- 场景 5: 安全防护 ---"
post "5.1 shell \$()"    '@ai-reviewer review $(whoami)'
post "5.3 pipe"          '@ai-reviewer review foo|bar'
post "5.4 cjk"          "@ai-reviewer review 请审查"
post "5.6 too many args" "@ai-reviewer review a b c d e f g h i j k l m n o p q"

# 5.5 超长命令行
LONG_ARG=$(printf 'a%.0s' {1..520})
post "5.5 overlong"      "@ai-reviewer review ${LONG_ARG}"

echo ""
echo "--- 场景 6: 对话 fallback ---"
post "6.1 convo issue"   "@ai-reviewer validators.ts 的 isValidUrl 正则为什么有 ReDoS 风险？"
post "6.3 bare mention"  "@ai-reviewer"

echo ""
echo "--- 场景 7: 无 @bot ---"
post "7   no mention"    "看起来改动不错，LGTM"

echo ""
echo "--- 场景 12: 标点容错 ---"
post "12a colon"         "@ai-reviewer: help"
post "12b comma"         "@ai-reviewer, help"
post "12c prefix"        "hi @ai-reviewer help"

echo ""
echo "--- 场景 13: 多行评论 ---"
MULTILINE="@ai-reviewer review
请仔细看看 validators.ts 中的正则
另外 formatPrice 的默认货币改成 USD 是否合适"
post "13  multiline"     "$MULTILINE"

echo ""
echo "============================================="
echo "  已发送 ${PASS}/${TOTAL} 条评论"
echo "============================================="
echo ""
echo "以下场景需要手工操作:"
echo ""
echo "  [场景 1.4]  Files changed tab → utils/validators.ts 行内评论:"
echo "              @ai-reviewer help"
echo ""
echo "  [场景 5.2]  反引号注入（Markdown 转义问题，需手贴原始文本）:"
echo "              @ai-reviewer review \`id\`"
echo ""
echo "  [场景 6.2]  Files changed tab → utils/validators.ts isValidUrl 行内:"
echo "              @ai-reviewer 这个正则有 ReDoS 风险吗？怎么修复？"
echo ""
echo "  [场景 9]    幂等: 重新运行已完成的 help workflow"
echo ""
echo "  [场景 10]   ACK 时序: 发 @ai-reviewer resolve 后持续刷新观察"
echo ""
echo "  [场景 11]   多账号权限: 用 read 权限账号发 @ai-reviewer pause"
echo ""

if [[ "$DRY" != "1" ]]; then
  echo "--- PR #${PR} 当前评论 ---"
  gh pr view "$PR" --json comments \
    --jq '.comments[] | "\(.author.login) [\(.createdAt[0:19])] \(.body[0:80])"' \
    2>/dev/null || echo "(无法获取评论)"
fi
