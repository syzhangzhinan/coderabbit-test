#!/bin/bash
# ============================================================================
# 测试组 11: 模型配置验证
# ============================================================================
# 验证功能点:
#   - openai_light_model: gpt-5.4-nano（摘要用）
#   - openai_heavy_model: gpt-5.4-mini（审查用）
#   - openai_model_temperature: 0.0
#   - openai_retries: 5（重试次数）
#   - openai_timeout_ms: 360000（超时）
#   - openai_concurrency_limit: 6（并发）
#   - github_concurrency_limit: 6（GitHub API 并发）
# ============================================================================
#
# ⚠️ 此测试主要通过观察 Action 日志验证，不需要特殊代码。
#    使用 01-core-review 的 PR 即可，检查 GitHub Actions 日志。
# ============================================================================

set -e
echo "🚀 [11] 模型配置验证"
echo ""
echo "此测试不需要单独分支，通过观察 GitHub Actions 日志验证："
echo ""
echo "🔍 验证清单（在 Actions 运行日志中检查）："
echo "  □ 日志显示使用 gpt-5.4-nano 进行文件摘要"
echo "  □ 日志显示使用 gpt-5.4-mini 进行代码审查"
echo "  □ 超时/重试配置生效（如遇 API 错误会重试 5 次）"
echo "  □ 并发请求数不超过 6"
echo ""
echo "📋 如需测试不同配置，修改 .github/workflows/ 中的 Action 参数："
echo ""
echo "  - name: AI Reviewer"
echo "    uses: syzhangzhinan/ai-reviewer@main"
echo "    with:"
echo "      openai_light_model: 'gpt-5.4-nano'"
echo "      openai_heavy_model: 'gpt-5.4-mini'"
echo "      openai_model_temperature: '0.0'"
echo "      openai_retries: '3'              # 改为 3 对比默认 5"
echo "      openai_timeout_ms: '120000'      # 改为 2分钟 对比默认 6分钟"
echo "      openai_concurrency_limit: '3'    # 改为 3 对比默认 6"
echo ""
