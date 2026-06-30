# AI Reviewer 测试指南

## 环境准备

### 脚本说明

| 脚本 | 用途 | 运行分支 |
|------|------|----------|
| `docs/generate-base.sh` | 生成干净正确的基线代码 | main |
| `docs/generate-issues.sh` | 在基线上引入问题代码 | feature/* |

### 操作步骤

```bash
# 1. 在 main 分支生成基线
git checkout main
chmod +x docs/generate-base.sh
./docs/generate-base.sh
git add -A && git commit -m "feat: add nuxt.js test project baseline"
git push origin main

# 2. 创建 feature 分支引入问题
git checkout -b feature/test-v2
chmod +x docs/generate-issues.sh
./docs/generate-issues.sh
git add -A && git commit -m "feat: introduce intentional issues for ai-reviewer testing"
git push origin feature/test-v2

# 3. 创建 PR 触发审查
gh pr create --base main --head feature/test-v2 --title "test: ai-reviewer full feature test"
```

## 功能覆盖矩阵

PR diff 中各文件变更对应触发的 ai-reviewer 功能：

| ai-reviewer 功能 | 触发文件/变更 |
|---|---|
| **跨文件依赖分析** | `utils/formatPrice.ts` 签名变更 → ProductCard/CartSummary 受影响 |
| | `utils/crypto-helper.ts` 实现替换 → `server/api/auth/login.post.ts` 受影响 |
| **ESLint** | `composables/useAuth.ts`(any 类型)、全项目 .ts/.vue |
| **Biome** | 新增 `utils/data-transform.ts`：`==`、`var`、死代码、`NaN` 比较 |
| **TSC** | strict 模式下类型不安全（any 使用） |
| **Semgrep** | 新增 `server/api/proxy.ts`(SSRF) |
| | 新增 `server/api/render.ts`(命令注入) |
| | 新增 `utils/object-utils.ts`(原型污染/正则注入/eval/路径遍历) |
| | `components/ReviewPanel.vue`(`v-html` XSS) |
| **review_simple_changes: false** | `types/constants.ts` 仅改版本号 → triage 应 APPROVED 跳过 |
| **enable_web_search** | `@supabase/supabase-js` 用法变更（SSR 单例问题） |
| **enable_shell** | `tsconfig.json` / `eslint.config.js` 触发 tsc/eslint |
| **增量审查** | 有 base commit 对比，`@codesentinel review` 只审增量 |

## 测试步骤

### 第一阶段：自动审查验证

1. PR 创建后等待 Bot 自动审查
2. 验证产出：
   - PR 摘要评论（Walkthrough + Changes 表格）
   - 行级审查评论（安全/逻辑/性能问题）
   - Release Notes 生成
3. 确认行级评论覆盖了 Semgrep/Biome/ESLint 发现的问题

### 第二阶段：命令系统测试

在 PR 评论中按顺序执行：

```
# 2.1 命令解析与路由
@codesentinel help                    → 展示所有命令用法
@ai-reviewer help                     → 别名同样触发
@codesentinel invalidcmd              → 提示无效命令
@CodeSentinel HELP                    → 大小写不敏感

# 2.2 权限（需不同权限账号）
# write 权限用户执行 review → 成功
# read 权限用户执行 review → FORBIDDEN

# 2.3 resolve 命令
@codesentinel resolve                 → 批量解决 Bot 评论 + 统计

# 2.4 审查控制命令
@codesentinel review                  → 触发增量审查
@codesentinel full review             → 全量审查
@codesentinel summary                 → 重新生成摘要
@codesentinel configuration           → 展示当前配置

# 2.5 暂停/恢复
@codesentinel pause                   → PR 描述写入暂停标记
（push 新 commit）                     → 不自动触发审查
@codesentinel resume                  → 恢复审查
（push 新 commit）                     → 触发审查

# 2.6 ACK 反馈
观察每个命令执行时：
- 评论上是否出现 🚀 表情（command_ack_reaction: rocket）
- 耗时命令是否有进度回帖
- 错误信息是否清晰

# 限流测试
快速连续发送 5 次 @codesentinel help    → 被限流
```

### 第三阶段：增量审查验证

1. Bot 完成首次审查后
2. 修改 `utils/formatPrice.ts`（如加一个新导出函数）并 push
3. 使用 `@codesentinel review` 触发增量审查
4. 验证仅审查新增 diff，已审查文件不重复

## 预期产出清单

| 编号 | 命令 | 期望行为 |
|------|------|----------|
| 2.1.1 | `@codesentinel help` | 展示所有命令 |
| 2.1.2 | `@ai-reviewer help` | 别名触发 |
| 2.1.3 | `@codesentinel xyz` | 无效命令提示 |
| 2.1.4 | `@CodeSentinel HELP` | 大小写不敏感 |
| 2.3.1 | `@codesentinel resolve` | 批量解决 |
| 2.4.1 | `@codesentinel review` | 增量审查 |
| 2.4.2 | `@codesentinel full review` | 全量审查 |
| 2.4.3 | `@codesentinel summary` | 重新摘要 |
| 2.4.4 | `@codesentinel pause` | 暂停标记 |
| 2.4.5 | `@codesentinel resume` | 恢复审查 |
| 2.4.6 | `@codesentinel configuration` | 配置展示 |
