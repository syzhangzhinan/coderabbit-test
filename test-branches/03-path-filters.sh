#!/bin/bash
# ============================================================================
# 测试组 03: 路径过滤 (path_filters)
# ============================================================================
# 验证功能点:
#   - 默认 path_filters 排除二进制/配置文件
#   - .lock / .json / .yaml / .yml 不审查
#   - .png / .zip 等二进制不审查
#   - dist/** 目录排除
#   - generated/** 目录排除
#   - max_files 限制（超出文件数时跳过统计）
# ============================================================================

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

BRANCH="feature/test-03-path-filters"
echo "🚀 [03] 路径过滤测试"
echo "   分支: $BRANCH"

git checkout main
git pull origin main 2>/dev/null || true
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 应被排除的文件（默认 path_filters）---

mkdir -p dist generated vendor

# 二进制/资产文件（应被跳过）
echo '{"name":"test","version":"1.0.0"}' > package-lock.json
echo 'lockfile content' > pnpm-lock-test.yaml
echo '# generated' > dist/index.js
echo '# generated' > generated/api-types.ts
echo '# vendor' > vendor/lodash.min.js

# 创建假的二进制文件
dd if=/dev/zero of=assets/test-image.png bs=1024 count=1 2>/dev/null
dd if=/dev/zero of=assets/test-archive.zip bs=1024 count=1 2>/dev/null

# 配置文件（默认被排除）
cat > test-config.yaml << 'EOF'
database:
  host: localhost
  password: insecure_password_in_yaml
EOF

cat > test-config.json << 'EOF'
{
  "apiKey": "sk-should-not-be-reviewed",
  "secret": "exposed-in-json"
}
EOF

# --- 应被审查的文件 ---

cat > utils/filter-test-reviewed.ts << 'EOF'
// 这个文件应该被正常审查
// 问题：SQL 注入（确认此文件被审查了）
export const query = (input: string) => `SELECT * FROM t WHERE x='${input}'`

// 问题：eval
export const run = (code: string) => eval(code)
EOF

git add -A
git commit -m "test: path filters - binary/config/generated files + reviewable .ts"

echo ""
echo "✅ 代码已提交到 $BRANCH"
echo ""
echo "📋 下一步："
echo "  git push origin $BRANCH"
echo "  gh pr create --base main --head $BRANCH --title 'test: 03-路径过滤验证'"
echo ""
echo "🔍 验证清单："
echo "  □ package-lock.json 不被审查"
echo "  □ .yaml/.json 配置文件不被审查"
echo "  □ dist/index.js 不被审查"
echo "  □ generated/api-types.ts 不被审查"
echo "  □ vendor/lodash.min.js 不被审查"
echo "  □ assets/test-image.png 不被审查"
echo "  □ assets/test-archive.zip 不被审查"
echo "  □ utils/filter-test-reviewed.ts 被正常审查并产出评论"
echo "  □ PR 摘要中有被跳过文件的统计"
