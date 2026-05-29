#!/usr/bin/env bash
#
# apply-changes.sh — 一键应用迭代三 Linter/SAST 集成的端到端测试代码改动（v2 自带工具版）
#
# 用法:
#   cd ai-reviewer-test
#   bash test_cases/iteration3-linter-sast/code-changes/apply-changes.sh
#
# 与 v1（manual-install）的差异:
#   - 待审查项目**无需**把 eslint / @biomejs/biome 写入 devDependencies
#   - 待审查项目**无需** biome.json（Biome 零配置可用）
#   - 待审查项目**无需** .codesentinel.yaml（默认就启用 eslint + biome）
#   - 仅保留一份最小 eslint.config.js（ESLint 9 必需）
#
# ai-reviewer 启动时会自动把 eslint + @biomejs/biome 装到 runner 的
# /tmp/ai-reviewer-lint-tools/ 沙箱里，约 +15s 冷启动开销。
#
# 步骤:
#   1. 创建测试分支 feature/lint
#   2. 拷贝最小 eslint.config.js 到仓库根
#   3. 在 utils/ 下新建 lint-test-cart.ts（含多种刻意问题）
#   4. 提交代码 + 推送 + 创建 PR

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

cd "$REPO_ROOT"
echo "工作目录: $(pwd)"

# 1. 创建/切换分支
BRANCH="feature/lint"
echo "==> 创建/切换分支 ${BRANCH}"
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# 2. 拷贝 ESLint Flat Config（ESLint 9 必需）
#    注意：Biome 不需要 biome.json，零配置即可工作 — 故不再拷贝
echo "==> 写入 eslint.config.js"
cp "$SCRIPT_DIR/eslint.config.js" eslint.config.js

# 3. 拷贝测试源文件
echo "==> 写入 utils/lint-test-cart.ts"
cp "$SCRIPT_DIR/lint-test-cart.ts" utils/lint-test-cart.ts

# 4. 暂存并提交（注意：不再修改 package.json，不再装本地工具）
git add eslint.config.js utils/lint-test-cart.ts

if git diff --cached --quiet; then
  echo "==> 暂存区无变更，跳过 git commit"
else
  git commit -m "test(iter3): add linter/SAST integration scenarios (bundled-tools v2)

- introduce utils/lint-test-cart.ts with intentional ESLint/Biome violations
- add minimal eslint.config.js (ESLint 9 Flat Config)
- ai-reviewer auto-installs eslint + biome to its sandbox at runtime;
  this PR does not modify package.json or install lint tools locally"
fi

# 5. 推送
echo "==> 推送分支 ${BRANCH}"
git push -u origin "$BRANCH"

# 6. 打开 PR
if command -v gh >/dev/null 2>&1; then
  gh pr create \
    --title "[iter3 v2] Linter/SAST 集成（自带工具版）端到端测试" \
    --body "测试入口。CI 触发后请验证：
- PR 摘要中的 \"🧰 Static Analysis Summary\" 表显示 ESLint/Biome 真实版本
- 每条匹配工具发现的评论尾部带 \"🧰 Tools\" 卡片
- 待审查项目本身**未**安装 eslint/biome 包（验证 bundled 路径生效）" \
    || echo "(PR 可能已存在，跳过创建)"
else
  echo "未检测到 gh CLI。请到 GitHub 上手动创建 PR。"
fi
