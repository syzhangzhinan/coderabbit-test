# 迭代二 · 命令框架（成员 A）— 端到端测试文档

> **测试目标**: 在 `ai-reviewer-test` 仓库中通过真实 PR 验证 ai-reviewer 命令框架的完整功能
> **对应功能**: [04-iteration-comment-interaction.md](../../ai-reviewer/docs/04-iteration-comment-interaction.md) — §2.1 命令系统设计
> **技术设计**: [04-iteration-02-member-a-design.md](../../ai-reviewer/docs/04-iteration-02-member-a-design.md)
> **适用 Action 分支**: `CodesSentinels/ai-reviewer@feature/cmd`

---

## 0. 概述

本文档描述如何在 `ai-reviewer-test` 仓库中进行真实端到端测试。测试分为 **三步走**：

1. **修改 workflow**：添加 `issue_comment` 事件支持 + 权限调整
2. **创建代码变更 PR**：提交一个包含代码改动的分支，触发初始 review
3. **在 PR 评论区逐条验证命令**：贴评论、观察 Bot 回复、核对预期

每个测试场景都包含：**输入评论**、**在哪里贴**、**期望 Bot 响应**、**实际要点**。

---

## 1. 前置准备

### 1.1 修改 Workflow 文件

> **必须先合并到目标分支（如 `main`）**，否则 `issue_comment` 触发器不会生效——GitHub Actions 只从默认分支读 `issue_comment` 的 workflow 配置。

将 `.github/workflows/ai-reviewer.yml` 替换为以下内容：

```yaml
name: Code Review

permissions:
  contents: read
  pull-requests: write
  issues: write          # 新增：Bot 需要在 issue_comment 事件下创建评论

on:
  pull_request:
    types: [opened, synchronize, reopened]
  pull_request_review_comment:
    types: [created]
  # ===== 迭代二新增 =====
  issue_comment:
    types: [created]

concurrency:
  group: >-
    ${{ github.repository }}-${{
      github.event.issue.number ||
      github.event.pull_request.number ||
      github.head_ref ||
      github.sha
    }}-${{ github.workflow }}-${{
      github.event_name == 'issue_comment' && 'issue_comment' ||
      github.event_name == 'pull_request_review_comment' && 'pr_comment' ||
      'pr'
    }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  review:
    runs-on: ubuntu-latest
    # issue_comment 也包含普通 issue；过滤掉非 PR 的事件
    if: >-
      github.event_name != 'issue_comment' ||
      github.event.issue.pull_request != null
    steps:
      - uses: CodesSentinels/ai-reviewer@feature/cmd
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        with:
          debug: true
          review_simple_changes: false
          review_comment_lgtm: false
          openai_heavy_model: gpt-4.1
```

**相比现有文件的变化**：

| 项 | 原值 | 新值 |
| :--- | :--- | :--- |
| `permissions.issues` | 无 | `write` |
| `on.issue_comment` | 无 | `types: [created]` |
| `concurrency.group` | 不含 `issue_comment` | 加入 `issue_comment` 独立 group |
| `jobs.review.if` | 无 | 过滤非 PR 的 issue_comment |
| Action 分支 | `@feature/vue` | `@feature/cmd` |

#### 操作命令

```bash
cd /path/to/ai-reviewer-test

# 直接编辑
cat > .github/workflows/ai-reviewer.yml << 'YAML'
# ... 粘贴上面的完整 YAML ...
YAML

git add .github/workflows/ai-reviewer.yml
git commit -m "ci: add issue_comment trigger for iter2 command framework test"
git push origin main
```

### 1.2 创建测试分支和代码变更

我们需要一个包含**代码改动**的 PR，这样 Bot 的初次自动 review 可以运行，之后我们在评论区发送各种命令进行测试。

以下提供 **四个改动文件**，每个文件都是对现有代码的**微小但有意义的修改**——既能触发 review，又提供了真实的代码上下文供对话追问测试使用。

```bash
git checkout -b test/iter2-cmd-framework
```

---

### 改动 1：`utils/validators.ts` — 新增一个有安全隐患的正则函数

这个改动是**故意引入 ReDoS 风险**的，AI review 应该能识别到。同时为后续 `@ai-reviewer 为什么这个正则有问题？` 的对话追问提供上下文。

**在文件末尾追加**：

```typescript
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
```

**操作**：
```bash
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
```

---

### 改动 2：`composables/useAuth.ts` — 修改函数签名（跨文件依赖测试）

为 `useAuth` 增加可选参数，同时引入一个**未 await 的 async 调用**让 AI 有审查素材。

**全文替换为**：

```typescript
/**
 * 认证 composable
 *
 * 迭代二命令框架测试 — 修改签名 + 引入 async 问题
 */
import { useUserStore } from "~/stores/userStore"
import { logInfo } from "~/base-layer/utils/logger"

export interface AuthOptions {
  redirectOnLogout?: boolean
  sessionTimeout?: number
}

export function useAuth(options: AuthOptions = {}) {
  const userStore = useUserStore()
  const isLoggedIn = computed(() => !!userStore.currentUser)

  async function login(email: string, password: string) {
    logInfo("login attempt", { email })
    // 故意：未 await 的 setUser（async 操作）
    userStore.setUser({ email, name: email.split("@")[0] })
    if (options.sessionTimeout) {
      setTimeout(() => {
        logout()
      }, options.sessionTimeout)
    }
  }

  async function logout() {
    logInfo("logout")
    userStore.clearUser()
    if (options.redirectOnLogout) {
      navigateTo("/")
    }
  }

  return { isLoggedIn, login, logout }
}
```

**操作**：
```bash
cat > composables/useAuth.ts << 'TS'
/**
 * 认证 composable
 *
 * 迭代二命令框架测试 — 修改签名 + 引入 async 问题
 */
import { useUserStore } from "~/stores/userStore"
import { logInfo } from "~/base-layer/utils/logger"

export interface AuthOptions {
  redirectOnLogout?: boolean
  sessionTimeout?: number
}

export function useAuth(options: AuthOptions = {}) {
  const userStore = useUserStore()
  const isLoggedIn = computed(() => !!userStore.currentUser)

  async function login(email: string, password: string) {
    logInfo("login attempt", { email })
    // 故意：未 await 的 setUser（async 操作）
    userStore.setUser({ email, name: email.split("@")[0] })
    if (options.sessionTimeout) {
      setTimeout(() => {
        logout()
      }, options.sessionTimeout)
    }
  }

  async function logout() {
    logInfo("logout")
    userStore.clearUser()
    if (options.redirectOnLogout) {
      navigateTo("/")
    }
  }

  return { isLoggedIn, login, logout }
}
TS
```

---

### 改动 3：`utils/formatPrice.ts` — 修改默认参数

```diff
 export function formatPrice(
   amount: number,
-  currency: string = "CNY",
+  currency: string = "USD",
   locale: string = "zh-CN"
 ): string {
```

**操作**：
```bash
sed -i '' 's/currency: string = "CNY"/currency: string = "USD"/' utils/formatPrice.ts
```

---

### 改动 4：新建 `utils/command-test-marker.ts` — 标记文件

一个微小的新文件，让 PR diff 更明确是在做命令框架测试。

```bash
cat > utils/command-test-marker.ts << 'TS'
/**
 * 迭代二 · 命令框架测试标记文件
 *
 * 本文件仅用于触发 PR review，不被其他代码引用。
 * 删除时不影响项目功能。
 */
export const ITERATION = 2
export const MODULE = "member-a-command-framework"
export const TEST_DATE = "2026-04-12"
TS
```

---

### 提交并创建 PR

```bash
git add utils/validators.ts composables/useAuth.ts utils/formatPrice.ts utils/command-test-marker.ts
git commit -m "test: iter2 command framework — code changes for review"
git push -u origin test/iter2-cmd-framework

gh pr create \
  --title "[TEST] 迭代二 · 命令框架端到端验证" \
  --body "$(cat << 'EOF'
## 目的

验证 ai-reviewer 迭代二 · 成员 A 命令框架功能：

- `@ai-reviewer help` / `@codesentinel help`
- `@ai-reviewer review` / `@ai-reviewer full review`
- `@ai-reviewer resolve` / `pause` / `resume` / `summary` / `configuration`
- 对话式追问 fallback
- 非法参数 / 权限 / 幂等 / ACK 时序

## 代码改动

1. `utils/validators.ts` — 新增 `isValidUrl`（故意 ReDoS）+ `isStrongPassword`
2. `composables/useAuth.ts` — 修改签名 + 未 await async
3. `utils/formatPrice.ts` — 默认货币 CNY → USD
4. `utils/command-test-marker.ts` — 测试标记文件

## 测试方法

按 `docs/05-iteration2-command-framework-test.md` 中的场景逐条在评论区发送命令。
EOF
)"
```

> 创建 PR 后记录下 PR 编号，后续用例中的 `#<PR>` 代表此编号。

---

## 2. 测试场景

> **贴评论位置说明**：
> - **PR Conversation tab**：PR 页面最下方的评论框 → 触发 `issue_comment` 事件
> - **Files changed tab 行内评论**：某行代码上点 `+` 号 → 触发 `pull_request_review_comment` 事件

---

### 场景 1：`help` 命令 — 基本可用性

**目的**：验证命令解析、注册表聚合、help handler 正确输出。

#### 1.1 标准 help

| 项 | 值 |
| :--- | :--- |
| 在哪贴 | PR Conversation tab |
| 评论内容 | `@ai-reviewer help` |
| 触发事件 | `issue_comment` |

**期望 Bot 回复**：

```
🤖 AI Reviewer · `help`

## 支持的命令

| 命令 | 描述 | 最低权限 |
| :--- | :--- | :------- |
| `@ai-reviewer review` | 触发增量审查... | `write` |
| `@ai-reviewer full review` | 触发全量审查... | `write` |
| `@ai-reviewer resolve` | 批量将所有... | `write` |
| `@ai-reviewer summary` | ... | `write` |
| `@ai-reviewer pause` | ... | `write` |
| `@ai-reviewer resume` | ... | `write` |
| `@ai-reviewer configuration` | ... | `read` |
| `@ai-reviewer help` | ... | `read` |

> 🤖 Bot 同时支持 `@ai-reviewer` 与 `@codesentinel` 两个 mention。
```

**验证点**：
- [ ] 回复在 30 秒内出现
- [ ] 表格列出了 8 条命令
- [ ] `help` 排在表格最后一行
- [ ] 评论 HTML 源码中包含 `<!-- codesentinel-cmd-reply:{评论ID}:help -->`

#### 1.2 别名 `@codesentinel`

| 项 | 值 |
| :--- | :--- |
| 在哪贴 | PR Conversation tab |
| 评论内容 | `@codesentinel help` |

**期望**：与 1.1 完全相同的回复内容。

**验证点**：
- [ ] `@codesentinel` 和 `@ai-reviewer` 产出相同结果

#### 1.3 大小写不敏感

| 项 | 值 |
| :--- | :--- |
| 在哪贴 | PR Conversation tab |
| 评论内容 | `@AI-Reviewer HELP` |

**期望**：同 1.1。

#### 1.4 review_comment 路径上的 help

| 项 | 值 |
| :--- | :--- |
| 在哪贴 | Files changed tab → 在 `utils/validators.ts` 的 `isValidUrl` 函数任意一行上添加行内评论 |
| 评论内容 | `@ai-reviewer help` |
| 触发事件 | `pull_request_review_comment` |

**期望**：同 1.1。

**验证点**：
- [ ] `pull_request_review_comment` 事件也正确进入命令框架

---

### 场景 2：复合命令 `full review`

**目的**：验证最长前缀匹配——`full review` 作为整体匹配，而非 `full`（不在白名单）。

| 项 | 值 |
| :--- | :--- |
| 在哪贴 | PR Conversation tab |
| 评论内容 | `@ai-reviewer full review` |

**期望 Bot 回复**（当前阶段，C 未接入，返回 NOT_IMPLEMENTED）：

```
🤖 AI Reviewer · `full review`

🚧 **命令暂未实现**。该命令已在路线图中，等待实现。

详情: Command not implemented: full review

`错误码: NOT_IMPLEMENTED`
```

**验证点**：
- [ ] 消息中的命令名是 `full review` **而非** `full`
- [ ] ACK → 先看到 `⏳ 正在执行 full review …`，随后同一条评论被更新为 NOT_IMPLEMENTED

---

### 场景 3：所有 stub 命令 NOT_IMPLEMENTED

逐条验证 B/C/D 尚未接入时的占位行为。

| # | 评论内容 | 期望命令名 | needsAck |
| :-: | :------- | :--------- | :------- |
| 3a | `@ai-reviewer review` | `review` | 是 |
| 3b | `@ai-reviewer full review` | `full review` | 是 |
| 3c | `@ai-reviewer resolve` | `resolve` | 是 |
| 3d | `@ai-reviewer summary` | `summary` | 是 |
| 3e | `@ai-reviewer pause` | `pause` | 否 |
| 3f | `@ai-reviewer resume` | `resume` | 否 |
| 3g | `@ai-reviewer configuration` | `configuration` | 否 |

**统一期望**：回复包含 `NOT_IMPLEMENTED` + 正确的命令名。

**验证点**：
- [ ] 3a~3d（needsAck=true）：先有 ⏳ ACK 评论，之后被编辑为最终结果
- [ ] 3e~3g（needsAck=false）：直接一条回复，无 ACK 中间态
- [ ] 每条回复的 HTML tag 中命令名正确

---

### 场景 4：命令参数解析

| 项 | 值 |
| :--- | :--- |
| 在哪贴 | PR Conversation tab |
| 评论内容 | `@ai-reviewer review files=utils/validators.ts` |

**期望**：参数被解析但 review stub 不消费参数，仍返回 NOT_IMPLEMENTED。

**验证点**：
- [ ] Bot 没有因为参数而报 INVALID_ARGS（`files=utils/validators.ts` 符合字符集）
- [ ] 命令名是 `review`

---

### 场景 5：安全防护 — 非法参数拦截

**目的**：验证 shell 元字符、字符集外字符、超长参数的拦截。

#### 5.1 shell 注入 `$()`

| 项 | 值 |
| :--- | :--- |
| 评论内容 | `@ai-reviewer review $(whoami)` |

**期望**：

```
🤖 AI Reviewer · `review`

⚠️ **参数不合法**。命令参数仅接受字母、数字以及 `._-/:=` 字符。

详情: 参数包含非法字符: `$(whoami)`

`错误码: INVALID_ARGS`
```

#### 5.2 反引号注入

| 项 | 值 |
| :--- | :--- |
| 评论内容 | `` @ai-reviewer review `id` `` |

**期望**：`INVALID_ARGS`，提到非法字符。

#### 5.3 管道符注入

| 项 | 值 |
| :--- | :--- |
| 评论内容 | `@ai-reviewer review foo\|bar` |

**期望**：`INVALID_ARGS`。

#### 5.4 中文参数（字符集外）

| 项 | 值 |
| :--- | :--- |
| 评论内容 | `@ai-reviewer review 请审查` |

**期望**：`INVALID_ARGS`，提到不允许的字符。

#### 5.5 超长命令行

贴一条包含 520 个 `a` 的命令：

```
@ai-reviewer review aaaaaaa...(共 520 个 a)
```

可用脚本生成：
```bash
echo "@ai-reviewer review $(printf 'a%.0s' {1..520})" | pbcopy
```

**期望**：`INVALID_ARGS`，提到命令长度超上限。

#### 5.6 参数个数超限

| 项 | 值 |
| :--- | :--- |
| 评论内容 | `@ai-reviewer review a b c d e f g h i j k l m n o p q` |

17 个参数，超过上限 16。

**期望**：`INVALID_ARGS`，提到参数个数超上限。

**统一验证点**：
- [ ] 5.1~5.6 全部返回 `INVALID_ARGS`
- [ ] 非法内容**不被回显到回复中**（除了 truncated 预览）
- [ ] Bot 没有执行任何 handler（无 ACK 评论，直接 error）

---

### 场景 6：对话 fallback（命令与对话共存）

**目的**：验证 `@ai-reviewer` 后跟非命令文本时走对话逻辑而非命令逻辑。

#### 6.1 PR Conversation tab 对话（issue_comment）

| 项 | 值 |
| :--- | :--- |
| 在哪贴 | PR Conversation tab |
| 评论内容 | `@ai-reviewer validators.ts 中新增的 isValidUrl 正则为什么会有 ReDoS 风险？请解释一下` |

**期望**：

当前阶段 `issue_comment` 上的对话 fallback **不回复**（仅 `pull_request_review_comment` 支持对话 fallback，`issue_comment` 上的对话由后续迭代的成员 D 实现）。

**在 Actions 日志中应看到**：
```
commentEvent: conversation fallback skipped (issue_comment 对话由后续迭代支持)
```

**验证点**：
- [ ] Bot 无任何回复（不是 UNKNOWN_COMMAND，而是完全静默的 fallback skip）
- [ ] Actions 日志中有上述 `conversation fallback skipped` 输出

#### 6.2 Files changed 行内评论对话（review_comment）

| 项 | 值 |
| :--- | :--- |
| 在哪贴 | Files changed tab → `utils/validators.ts` 的 `isValidUrl` 正则那一行 |
| 评论内容 | `@ai-reviewer 这个正则有 ReDoS 风险吗？怎么修复？` |
| 触发事件 | `pull_request_review_comment` |

**期望**：

Bot 走原有的 `handleReviewComment` 对话逻辑，给出关于正则 ReDoS 的解释回复。回复内容是 AI 生成的自由格式文本（不是命令框架的结构化回复，不含 `codesentinel-cmd-reply` tag）。

**验证点**：
- [ ] Bot 回复了（不是 NOT_IMPLEMENTED / INVALID_ARGS 等命令错误）
- [ ] 回复内容与正则安全相关，带有上下文
- [ ] 回复评论的 HTML 中**不包含** `codesentinel-cmd-reply`（是对话回复，不是命令回复）

#### 6.3 仅 `@ai-reviewer` 无内容

| 项 | 值 |
| :--- | :--- |
| 评论内容 | `@ai-reviewer` |

**期望**：视为对话触发，同 6.1/6.2 的 fallback 路径。

---

### 场景 7：完全忽略（无 @bot 提及）

| 项 | 值 |
| :--- | :--- |
| 评论内容 | `看起来改动不错，LGTM` |

**期望**：Bot 无任何回复。Actions 甚至不应触发（无 `@` 提及时 workflow 可能仍启动，但 dispatcher 立即返回 `ignored: no bot mention`）。

**验证点**：
- [ ] 无新评论
- [ ] （若能看到 Actions 日志）日志中有 `no bot mention`

---

### 场景 8：Bot 自评论不循环

**目的**：确认 Bot 自己发出的评论不会触发新一轮处理。

**操作**：无需手动操作——场景 1 中 Bot 回复 help 时就会产生一条评论。

**验证点**：
- [ ] Bot 的 help 回复之后，**没有**再出现新的 Bot 回复（无自我循环）
- [ ] （若看日志）日志中有 `comment from bot` 的 ignored 记录

---

### 场景 9：幂等 — 重复处理防护

**目的**：确认同一条评论不会被处理两次。

**操作**：

1. 先执行场景 1.1（`@ai-reviewer help`），确认收到回复
2. 进入 Actions → 找到 help 对应的 workflow run → 点击 "Re-run all jobs"
3. 等待 run 完成

**期望**：**不产生第二条 help 回复**。

**在重新运行的 Actions 日志中应看到**：
```
command dispatcher: skip duplicate commentId=... cmd=help
```

**验证点**：
- [ ] PR 评论区仅有一条 help 回复（来自首次处理）
- [ ] Actions 日志确认了 `DUPLICATE` 跳过

---

### 场景 10：ACK → 最终结果时序

**目的**：验证 `needsAck=true` 的命令先产生 ⏳ 占位消息，然后编辑为最终结果。

| 项 | 值 |
| :--- | :--- |
| 评论内容 | `@ai-reviewer resolve` |

**观察方法**：发出评论后，**持续刷新 PR 页面**（或使用浏览器 DevTools Network 监控 API 调用）。

**期望时序**：

1. **先看到**（约 3~8 秒内）：
   ```
   🤖 AI Reviewer · `resolve`

   ⏳ 正在执行 `resolve` …
   ```

2. **随后同一条评论更新为**：
   ```
   🤖 AI Reviewer · `resolve`

   🚧 **命令暂未实现**。...
   ```

**验证点**：
- [ ] 是**同一条评论被编辑**（评论 ID 不变），而非新增第二条
- [ ] ACK 消息在结果消息之前可见（哪怕只有几秒）

---

### 场景 11：权限校验

> 此场景需要**两个 GitHub 账号**：一个拥有仓库 `write` 权限（主账号），一个仅有 `read` 权限（测试账号）。
> 如果只有单账号，可在仓库 Settings → Collaborators 中临时调整权限进行测试。

#### 11.1 read 用户执行需要 write 的命令

| 项 | 值 |
| :--- | :--- |
| 操作账号 | read 权限账号 |
| 评论内容 | `@ai-reviewer pause` |

**期望**：

```
🤖 AI Reviewer · `pause`

🚫 **权限不足**。执行该命令需要仓库 `write` 及以上权限。

详情: 用户 `{read-account}` 当前权限: `read`

`错误码: FORBIDDEN`
```

#### 11.2 read 用户执行 help（min=read，应通过）

| 项 | 值 |
| :--- | :--- |
| 操作账号 | read 权限账号 |
| 评论内容 | `@ai-reviewer help` |

**期望**：正常返回 help 信息（不报 FORBIDDEN）。

#### 11.3 PR 作者豁免

| 项 | 值 |
| :--- | :--- |
| 操作账号 | PR 作者（即创建测试 PR 的账号） |
| 评论内容 | `@ai-reviewer review` |

即使 PR 作者只有 `read` 权限，`review` 也应通过权限检查（走 PR 作者豁免路径），然后进入 review stub → NOT_IMPLEMENTED。

#### 11.4 PR 作者豁免不扩展到 pause

| 项 | 值 |
| :--- | :--- |
| 操作账号 | PR 作者（read 权限） |
| 评论内容 | `@ai-reviewer pause` |

**期望**：`FORBIDDEN`（pause 不在豁免列表中）。

---

### 场景 12：mention 后紧跟标点

验证解析器对 `@ai-reviewer:` / `@ai-reviewer,` 等常见写法的容错。

| # | 评论内容 | 期望 |
| :--- | :------- | :--- |
| 12a | `@ai-reviewer: help` | 正常返回 help |
| 12b | `@ai-reviewer, help` | 正常返回 help |
| 12c | `hi @ai-reviewer help` | 正常返回 help |

---

### 场景 13：多行评论 — 仅取首行命令

| 项 | 值 |
| :--- | :--- |
| 评论内容 | （多行） |

```
@ai-reviewer review
请仔细看看 validators.ts 中的正则
另外 formatPrice 的默认货币改成 USD 是否合适
```

**期望**：命令名 = `review`，`rawAfter` 包含后续行文本。由于 review 是 stub，返回 NOT_IMPLEMENTED。

**验证点**：
- [ ] 仅识别 `review` 命令，后续行不影响解析
- [ ] 未报 INVALID_ARGS（后续行内容不参与参数校验）

---

## 3. 半自动测试脚本

以下脚本通过 `gh` CLI 批量发送上述评论。需在 `ai-reviewer-test` 仓库目录下运行。

```bash
#!/usr/bin/env bash
# usage: PR=<number> bash docs/run-iter2-test.sh
#   DRY=1 PR=123 bash docs/run-iter2-test.sh   # 仅打印不发送

set -euo pipefail
: "${PR:?请设置 PR 编号: PR=123 bash $0}"
DRY="${DRY:-0}"
WAIT="${WAIT:-35}"

post() {
  local label="$1"; shift
  local body="$*"
  echo "[$label] $body"
  [[ "$DRY" == "1" ]] && return
  gh pr comment "$PR" --body "$body"
  echo "  → 等待 ${WAIT}s ..."
  sleep "$WAIT"
}

echo "=== 迭代二命令框架测试 · PR #${PR} ==="
echo ""

post "1.1 help"            "@ai-reviewer help"
post "1.2 alias"           "@codesentinel help"
post "1.3 case"            "@AI-Reviewer HELP"
post "2   full review"     "@ai-reviewer full review"
post "3a  review"          "@ai-reviewer review"
post "3c  resolve"         "@ai-reviewer resolve"
post "3e  pause"           "@ai-reviewer pause"
post "3f  resume"          "@ai-reviewer resume"
post "3g  configuration"   "@ai-reviewer configuration"
post "4   kv args"         "@ai-reviewer review files=utils/validators.ts"
post "5.1 shell \$()"      '@ai-reviewer review $(whoami)'
post "5.3 pipe"            '@ai-reviewer review foo|bar'
post "5.4 cjk"            "@ai-reviewer review 请审查"
post "5.6 too many args"   "@ai-reviewer review a b c d e f g h i j k l m n o p q"
post "6.1 convo issue"     "@ai-reviewer validators.ts 的 isValidUrl 正则为什么有 ReDoS 风险？"
post "7   no mention"      "看起来改动不错，LGTM"
post "12a colon"           "@ai-reviewer: help"
post "12b comma"           "@ai-reviewer, help"

# 5.5 超长
LONG_ARG=$(printf 'a%.0s' {1..520})
post "5.5 overlong"        "@ai-reviewer review ${LONG_ARG}"

echo ""
echo "=== 脚本完成 ==="
echo "请手工完成以下无法自动化的场景:"
echo "  - 场景 1.4: Files changed tab 行内 help"
echo "  - 场景 5.2: 反引号注入（Markdown 会转义，需手工贴）"
echo "  - 场景 6.2: Files changed 行内对话追问"
echo "  - 场景 9:   Re-run workflow 幂等测试"
echo "  - 场景 10:  观察 ACK → 最终结果时序"
echo "  - 场景 11:  多账号权限测试"
echo "  - 场景 13:  多行评论"
echo ""
echo "PR 评论列表:"
[[ "$DRY" != "1" ]] && gh pr view "$PR" --json comments \
  --jq '.comments[] | "\(.author.login) [\(.createdAt)] \(.body[0:100])"'
```

将此脚本保存为 `docs/run-iter2-test.sh` 后运行：

```bash
chmod +x docs/run-iter2-test.sh
PR=<你的PR编号> bash docs/run-iter2-test.sh

# 仅打印不发送
DRY=1 PR=123 bash docs/run-iter2-test.sh
```

---

## 4. 验收核对表

完成所有场景后，填写以下表格：

| # | 场景 | 通过? | 备注 |
| :-: | :--- | :---: | :--- |
| 1.1 | help 基本 | | |
| 1.2 | @codesentinel 别名 | | |
| 1.3 | 大小写不敏感 | | |
| 1.4 | review_comment 路径 help | | |
| 2 | full review 复合命令 | | |
| 3a~g | 所有 stub NOT_IMPLEMENTED | | |
| 4 | kv 参数合法透传 | | |
| 5.1 | shell $() 拦截 | | |
| 5.2 | 反引号拦截 | | |
| 5.3 | 管道符拦截 | | |
| 5.4 | 中文参数拦截 | | |
| 5.5 | 超长命令行拦截 | | |
| 5.6 | 参数个数超限拦截 | | |
| 6.1 | issue_comment 对话 fallback | | |
| 6.2 | review_comment 对话 fallback | | |
| 6.3 | 单独 @bot | | |
| 7 | 无 @bot 忽略 | | |
| 8 | Bot 自评论不循环 | | |
| 9 | 幂等去重 | | |
| 10 | ACK → 最终结果时序 | | |
| 11.1 | read 用户 FORBIDDEN | | |
| 11.2 | read 用户 help 通过 | | |
| 11.3 | PR 作者豁免 review | | |
| 11.4 | PR 作者豁免不含 pause | | |
| 12a~c | 标点容错 | | |
| 13 | 多行仅取首行 | | |

**验收标准**：
- **P0 必过**（26 项）：1.1~1.4、2、3a~g、4、5.1~5.6、6.1~6.3、7、8、10、12a~c、13
- **P1 必过**（4 项）：9、11.1~11.4
- 全部通过即可宣布**成员 A 交付验收完成**

---

## 5. 常见问题排查

| 现象 | 可能原因 | 解决方法 |
| :--- | :------- | :------- |
| 贴评论后 Actions 未触发 | `issue_comment` workflow 未合入默认分支 | 确保 §1.1 的修改已 push 到 `main` |
| Actions 触发了但 Bot 无回复 | Payload 中 `issue.pull_request` 为 null | 确认是在 PR（非 Issue）上评论 |
| Bot 回复 "Skipped: this action only works on push events" | Action 分支仍指向旧版（无 issue_comment 支持） | 确认 workflow 中 `uses:` 指向 `@feature/cmd` |
| FORBIDDEN 但我有 write 权限 | `getCollaboratorPermissionLevel` 缓存了旧权限 | 重新触发 workflow（Re-run） |
| 反引号测试无效 | GitHub Markdown 把反引号渲染为 code | 检查 PR 评论原始 body 是否确实包含 `` ` `` |
| 幂等测试发现第二次仍然回复 | listComments 未扫到已有 tag | PR 评论超过 100 条时需扩大扫描范围 |
| ACK 看不到，直接看到最终结果 | Bot 执行太快，create→update 间隔 <1s | 正常现象；stub 无真实耗时，可通过 Actions 日志中的时间戳确认 ACK 逻辑确实执行 |

---

## 6. 清理

测试完成后：

```bash
# 关闭并删除测试 PR 分支
gh pr close <PR编号> --delete-branch

# 如需恢复 workflow
git checkout main
# 将 action 分支改回原版
sed -i '' 's|@feature/cmd|@feature/vue|' .github/workflows/ai-reviewer.yml
# 如不需要 issue_comment 触发器也可移除
git add .github/workflows/ai-reviewer.yml
git commit -m "ci: revert to original workflow after iter2 testing"
git push
```
