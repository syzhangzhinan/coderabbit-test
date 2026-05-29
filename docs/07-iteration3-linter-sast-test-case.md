# 迭代三 · Linter/SAST 集成 — 端到端测试文档（v2 自带工具版）

> **测试目标**: 在 `ai-reviewer-test` 仓库中通过真实 PR 验证 ai-reviewer 的 Linter/SAST
> 集成。本版本采用**自带工具策略** —— 待审查项目无需安装 eslint/biome 包。
>
> **对应功能**: [05-iteration-linter-sast.md](../../codesentinel-docs/docs/product-plan/05-iteration-linter-sast.md)
>
> **技术设计**: [06-iteration-linter-sast-design.md](../../ai-reviewer/docs/06-iteration-linter-sast-design.md) /
> [07-linter-sast-architecture.md](../../ai-reviewer/docs/07-linter-sast-architecture.md)
>
> **本测试覆盖**:
> - **零侧装依赖**：`package.json` 不变、`node_modules` 不必有 eslint/biome
> - ESLint + Biome 集成（ai-reviewer 自动从 npm 装到 `/tmp` 沙箱）
> - 变更行过滤、`.codesentinel.yaml` 配置（可选）
> - Prompt 注入、评论标注（🧰 Tools）、PR 摘要中的工具统计表
> - 容错（npm 不可达/install 失败时不阻塞审查）

---

## 0. 概述：相比 v1 的简化

| 维度 | v1（手动安装）— 已废弃 | v2（自带工具）— 当前 |
|:-----|:---------------------|:-------------------|
| 项目 `package.json` | 必须加 `eslint@^9` + `@biomejs/biome@^2` | **不动** |
| Workflow `npm install` 步骤 | 必须 | **不需要** |
| `actions/checkout` | 必须 | 必须 |
| `biome.json` / `.codesentinel.yaml` | 推荐 | 全部**可选** |
| 冷启动开销 | ~5s（`npm install`） | ~15s（首次安装到 `/tmp` 沙箱，后续 job 通过 GitHub Actions cache 可加速） |

测试方法：

1. 一次性更新 workflow（仅需 setup-node + checkout + ai-reviewer 三步）
2. 跑 `apply-changes.sh` 创建测试分支
3. PR 触发 CI；按下文场景表逐项验证

---

## 1. 前置准备

### 1.1 Workflow 文件

把 `.github/workflows/ai-reviewer.yml` 改为**仅包含三步**（注意：v1 的 `npm install` 兜底不再需要）：

```yaml
name: Code Review

permissions:
  contents: read
  pull-requests: write
  issues: write

on:
  pull_request:
    types: [opened, synchronize, reopened]
  pull_request_review_comment:
    types: [created]
  issue_comment:
    types: [created]

concurrency:
  group: ${{ github.repository }}-${{ github.event.number || github.head_ref || github.sha }}-${{ github.workflow }}
  cancel-in-progress: ${{ github.event_name != 'pull_request_review_comment' }}

jobs:
  review:
    runs-on: ubuntu-latest
    if: >-
      github.event_name != 'issue_comment' ||
      github.event.issue.pull_request != null
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - uses: actions/checkout@v4
      - uses: CodesSentinels/ai-reviewer@feature/lint
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        with:
          debug: true
          enable_lint_tools: true
          review_simple_changes: false
          review_comment_lgtm: false
          openai_heavy_model: gpt-5.4-mini
          enable_shell: false
          enable_web_search: false
          enable_dependency_analysis: false
```

> ⚠️ workflow 文件**所在分支必须能让 GitHub 读取到** —— 对 `pull_request` 事件来说，
> workflow 文件来自 PR 分支；对 `pull_request_target` 来说来自 base 分支。
> 当前测试用 `pull_request`，所以更新 PR 分支上的 workflow 即可。

### 1.2 测试用代码改动

```bash
cd ai-reviewer-test
bash test_cases/iteration3-linter-sast/code-changes/apply-changes.sh
```

脚本只做四件事：

1. 创建/切到 `feature/lint` 分支
2. 把 `eslint.config.js`（最小 Flat Config）拷贝到仓库根
3. 在 `utils/lint-test-cart.ts` 写入故意带问题的 TS 代码
4. 提交 + 推送 + 创建 PR

**`package.json` 不会被修改，`node_modules` 也不会动。**

### 1.3 验证待审查项目"什么都没装"

```bash
cd ai-reviewer-test
git checkout feature/lint
grep -E '"eslint"|"@biomejs/biome"' package.json
# 输出应为空（没有匹配） → 项目侧确实没装 lint 工具
```

---

## 2. 测试场景列表

每个场景：**预期工具发现** + **预期 AI 行为** + **观察点**。

> 通用前置：所有场景都基于"待审查项目自身没装 eslint/biome"这一事实。
> ai-reviewer 启动时会在 runner 的 `/tmp/ai-reviewer-lint-tools/` 自动装这两个工具。

### 2.1 场景 A — `array-callback-return` + 业务逻辑错误（强 AI 用例）

**目标代码**: `utils/lint-test-cart.ts::calculateTotal`

```ts
items.map((item) => {
  total += item.quantity   // 缺 return + 错把 quantity 当价格
})
```

**预期工具发现**:

| 工具 | 规则 | 严重级别 |
|:----|:----|:--------|
| ESLint | `array-callback-return` | error |
| Biome | `lint/suspicious/useIterableCallbackReturn` | error |

**预期 AI 行为**:

- 对 `items.map(...)` 行写一条评论
- 命名工具（"ESLint reports …"）并解释影响
- 额外指出**业务逻辑错误**（应 `* item.price`）
- 评论尾部带 "🧰 Tools" 卡片

**通过条件**: 评论同时覆盖 lint 发现 **和** 业务逻辑错误。

#### 2.1.x 排查方向：AI 漏判逻辑错误时

按以下顺序定位：

1. 看日志 `triage:` —— `APPROVED` 表示 lightBot 跳过了重量审查 → 临时把 `review_simple_changes` 设为 `true`
2. 看日志是否有 `lgtm` —— 重量模型可能产了 LGTM 但被过滤
3. 看统计表中 ESLint/Biome 是否 `_unavailable_` —— 工具失败时 prompt 里不拼 MANDATORY 指令

---

### 2.2 场景 B — `no-unused-vars` + `eqeqeq`

**目标代码**: `utils/lint-test-cart.ts::isValidItemId`

```ts
const tempData = "reserved-for-future-use"   // 未使用
if (id == null) return false                  // 应使用 ===
```

**预期工具发现**:

| 工具 | 规则 | 严重级别 |
|:----|:----|:--------|
| ESLint | `no-unused-vars` | error |
| ESLint | `eqeqeq` | error |
| Biome | `lint/correctness/noUnusedVariables` | error |
| Biome | `lint/suspicious/noDoubleEquals` | error |

**预期 AI 行为**: 两个发现都对应到正确行；跨工具去重生效（同一行 `tempData` 不应同时出现 ESLint 与 Biome 两条评论）。

---

### 2.3 场景 C — `no-console` + 业务盲区

**目标代码**: `utils/lint-test-cart.ts::addToCart`

```ts
console.log(`adding item to cart: ${item.id}`)
cartItems.value.push(item)
```

**预期工具发现**: ESLint `no-console` (warning)

**预期 AI 行为**: 评论包含工具确认 + 业务盲区补充（"直接 push 不去重，缺少库存上限校验"）。

---

### 2.4 场景 D — `URLSearchParams.map` 误用（纯 AI 用例）

**目标代码**: `utils/lint-test-cart.ts::debugQuery`

工具不会检出（因 `as unknown as` 让类型已变）。AI 应该指出 `URLSearchParams` 没有 `map`，建议 `forEach`。

**通过条件**: 评论指出错误并给出 `diff` 修复，且评论尾部**没有** `🧰 Tools` 卡片（因为没有工具发现）。

---

### 2.5 场景 E — PR 摘要的工具统计表

**预期内容**:

```
🧰 Static Analysis Summary (2 tools)

| Tool         | Errors | Warnings | Files Scanned | Duration |
| ESLint 9.x.x |  ≥3   |    ≥1    |       ≥1      | <60000ms |
| Biome 2.x.x  |  ≥3   |     0    |       ≥1      | <60000ms |
```

**通过条件**: 表格存在，工具版本可见，统计与实际发现数一致（误差 ±1）。

---

### 2.6 场景 F — 验证零侧装：项目 `node_modules` 不含 lint 工具

**目标**: 显式验证"待审查项目什么都没装"这件事。

**触发方式**:

在跑 PR 触发的 workflow 之外，本地手动执行：

```bash
cd ai-reviewer-test
git checkout feature/lint
ls node_modules/ 2>&1 | head -5      # 项目 node_modules 内容
ls node_modules/.bin/eslint 2>&1     # 应输出"No such file"
ls node_modules/.bin/biome 2>&1      # 应输出"No such file"
```

**workflow 触发后查看 GitHub Actions 日志**:

应能看到：

```
lint/installer: installing eslint@^9.15.0 → /tmp/ai-reviewer-lint-tools
lint/installer: eslint ready at /tmp/ai-reviewer-lint-tools/node_modules/.bin/eslint
lint/installer: installing @biomejs/biome@^2.3.0 → /tmp/ai-reviewer-lint-tools
lint/installer: biome ready at /tmp/ai-reviewer-lint-tools/node_modules/.bin/biome
lint/eslint: bundled bin=/tmp/ai-reviewer-lint-tools/node_modules/.bin/eslint, project config=eslint.config.js
lint/biome: bundled bin=/tmp/ai-reviewer-lint-tools/node_modules/.bin/biome, zero-config OK
```

**通过条件**: 日志中工具的 `binPath` 都指向 `/tmp/ai-reviewer-lint-tools/`（沙箱），不是 `node_modules/.bin/`。

---

### 2.7 场景 G — npm 不可达时的容错

**触发方式**: 在 workflow 中**故意把 npm registry 替换为不可达地址**（仅测试时）：

```yaml
- run: npm config set registry http://127.0.0.1:1   # 故意指向不可达
- uses: CodesSentinels/ai-reviewer@feature/lint
  ...
```

**预期**:

- 沙箱安装超时或连接失败
- 统计表中 ESLint/Biome 都显示 `_unavailable_`，reason 列写：
  > `bundled ESLint install failed: npm install eslint@^9.15.0 failed (exit=1): ...`
- 整体 review 不被打断（AI 评论照常）
- 跑完后**记得把 registry 改回**：`npm config delete registry`

**通过条件**: 工具不可用不阻塞审查。

---

### 2.8 场景 H — 关闭整个 Lint 阶段

```yaml
with:
  enable_lint_tools: false
```

**预期**:

- 日志：`Phase 0b: lint tools disabled by config, skipping`
- PR 摘要中**没有** "🧰 Static Analysis Summary"
- 行级评论尾部**没有** "🧰 Tools" 标注
- 沙箱安装也不会触发（节省时间）

---

### 2.9 场景 I — 变更行过滤

**触发方式**: 在 PR 上追加一个"只改注释"的 commit。

**预期**: 工具仍扫描整个文件，但只有变更行附近 ±3 行的发现进入评论。统计表"findings on changed lines"反映实际命中数。

---

### 2.10 场景 J — 项目无 ESLint 配置时的行为

**触发方式**: 手动从分支删除 `eslint.config.js`，重新触发 review。

**预期**:

- 沙箱安装 ESLint 成功
- 但 `EslintAdapter.detect()` 检测到无 config → 返回 `available: false`
- 统计表中 ESLint 显示 `_unavailable_`，reason 列：
  > `no ESLint config found in repo (looked for eslint.config.{js,mjs,cjs,ts,mts,cts}, .eslintrc.*, package.json#eslintConfig)`
- Biome 仍正常工作（零配置）

**通过条件**: ESLint 优雅降级，Biome 不受影响。

---

### 2.11 场景 K — 杠杆 A：无 finding 文件零 token 浪费

**触发方式**: 在 PR 中混合"有问题的 ts 文件"和"干净的 ts 文件"。

预期：干净文件的 doReview prompt 中**不包含** "Static analysis tool results" 段头与 MANDATORY 指令；调试日志中 `injected lint context for ...` 仅对有 finding 的文件出现。

---

### 2.12 场景 L — 工具沙箱缓存命中

**触发方式**: 在同一 PR 上连续 push 两个 commit。

**预期**:

- 第一个 commit 的 review：日志显示 `lint/installer: installing ...`（首次安装）
- 第二个 commit 的 review：日志显示 `lint/installer: cache hit for eslint → ...`（同一 runner job 内复用沙箱）

> ⚠️ 跨 job 默认不缓存。如需跨 job 缓存以省 ~15s，在 workflow 加：
>
> ```yaml
> - uses: actions/cache@v4
>   with:
>     path: /tmp/ai-reviewer-lint-tools
>     key: ai-reviewer-lint-tools-${{ runner.os }}-eslint9-biome2
> ```

**通过条件**: 第二个 commit 的工具相关日志体现了"cache hit"，且 PR 评论仍正确包含 lint 发现。

---

## 3. 测试执行顺序建议

| 步骤 | 场景 | 备注 |
|:-----|:-----|:-----|
| 1 | A、B、C、D、E、K | 主 PR 一次性覆盖 |
| 2 | F | PR 触发后查日志即可，无额外操作 |
| 3 | L | 在主 PR 上 push 一个无关 commit 触发第二次 review |
| 4 | I | 在主 PR 上追加只改注释的 commit |
| 5 | J | 删除 `eslint.config.js` 触发新 review |
| 6 | H | 改 workflow 输入参数 |
| 7 | G | （可选，破坏性较强）改 npm registry |

---

## 4. 失败排查

| 现象 | 可能原因 | 排查 |
|:-----|:---------|:-----|
| 没有 lint 评论 | `enable_lint_tools=false` 或工具安装失败 | 看日志 Phase 0b 区段 |
| 统计表全 `_unavailable_`，reason 含 "npm install ... failed" | runner 无法访问 npm | 见场景 G 分析；自托管 runner 需配置 npm 镜像 |
| 统计表中 ESLint 显示 `no ESLint config found` | 项目没有 `eslint.config.js` | 加一个最小 Flat Config（参考 `test_cases/iteration3-linter-sast/code-changes/eslint.config.js`） |
| 评论尾部 `🧰 Tools` 卡片缺失 | 工具发现行号不在评论范围内 | 查日志 `injected lint context for ...` |
| 冷启动 60s 仍超时 | runner 网络极慢 | 提高 `INSTALL_TIMEOUT_MS`（在 ai-reviewer 的 `tool-installer.ts`），或本地预装 + 用 `actions/cache` 持久化 |

---

## 5. 单元测试入口

仓库内附带五组单元测试，可在 ai-reviewer 本地直接跑：

```bash
cd ../ai-reviewer
npm test -- \
  __tests__/lint-diff-filter.test.ts \
  __tests__/lint-orchestrator.test.ts \
  __tests__/lint-prompt-injection.test.ts \
  __tests__/lint-eslint-config-detection.test.ts \
  __tests__/lint-tool-installer.test.ts
```

预期：

| 测试文件 | 用例数 |
|:--------|:------|
| `lint-diff-filter.test.ts` | 8 |
| `lint-orchestrator.test.ts` | 4 |
| `lint-prompt-injection.test.ts` | 4 |
| `lint-eslint-config-detection.test.ts` | 7 |
| `lint-tool-installer.test.ts` | **7（新增，多策略 dispatcher）** |

ai-reviewer 全部测试 220 个用例均通过。

---

## 6. 验收清单

| 验收项 | 通过标准 |
|:-------|:---------|
| ✅ 项目侧零负担 | 场景 F 通过：`package.json` 不含 lint 工具，`node_modules` 中没有它们的 bin |
| ✅ 自带工具有效 | 场景 E + F：统计表显示 ESLint 9.x / Biome 2.x，binPath 指向 `/tmp/ai-reviewer-lint-tools/` |
| ✅ 缓存复用 | 场景 L：同 job 内第二次调用日志含 "cache hit" |
| ✅ 工具发现注入 LLM | 场景 A/B/C：AI 评论命名工具并解释 |
| ✅ AI 交叉验证 | 场景 A/C：评论同时覆盖工具发现 + 工具盲区 |
| ✅ ESLint 项目无配置时优雅降级 | 场景 J 通过 |
| ✅ npm 不可达时不阻塞 | 场景 G：reason 列清晰，AI 审查照常 |
| ✅ 总开关 | 场景 H 通过 |
| ✅ 杠杆 A：无 finding 文件零 token 浪费 | 场景 K 通过 |
| ✅ 变更行过滤 | 场景 I 通过 |
