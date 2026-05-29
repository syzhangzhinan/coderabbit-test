# AI Reviewer — Nuxt/Vue 依赖分析测试用例

本文档详细说明每个测试场景的测试点、涉及文件、代码修改方式和预期结果。
用于在 GitHub PR 中验证 `enable_dependency_analysis` 对 Nuxt/Vue 技术栈的支持。

---

## 项目结构

```
ai-reviewer-test/
├── nuxt.config.ts                    # extends: ['./base-layer']
├── app.vue                           # 根组件（入口文件，不参与依赖分析）
├── composables/
│   ├── useAuth.ts                    # 场景 1, 8
│   └── useCart.ts                    # 场景 2
├── utils/
│   ├── formatPrice.ts               # 场景 3
│   └── validators.ts
├── components/
│   ├── ProductCard.vue              # 场景 3, 4, 6, 10
│   ├── CartSummary.vue              # 场景 1, 2, 3, 4
│   ├── HeavyChart.vue              # 场景 9, 10, 11, 12
│   ├── ReviewPanel.vue             # 场景 9
│   ├── DynamicRenderer.vue         # 场景 10 (<component :is> + import)
│   ├── RuntimeDynamic.vue          # 场景 11 (限制: 运行时动态组件)
│   ├── DynamicPathImport.vue       # 场景 12 (限制: 模板字符串 import)
│   └── ui/
│       └── BaseButton.vue           # 场景 4
├── pages/
│   ├── index.vue                    # 场景 1 (auto-import)
│   ├── cart.vue                     # 场景 2 (auto-import)
│   ├── dashboard.vue               # 场景 9 (defineAsyncComponent)
│   └── products/
│       └── [id].vue                 # 场景 3
├── layouts/
│   └── default.vue                  # 场景 6, 7
├── stores/
│   └── userStore.ts                 # 场景 5, 8
└── base-layer/                      # Nuxt extends 层
    ├── nuxt.config.ts
    ├── composables/
    │   └── useTheme.ts              # 场景 6
    ├── components/
    │   └── AppHeader.vue            # 场景 7
    └── utils/
        └── logger.ts                # 场景 8
```

---

## 场景 1: Composable 显式导入

### 测试点

- `.vue` 文件中 `<script setup>` 内的 **ES6 named import** 能被解析
- 修改 composable 的导出函数签名时，显式导入方被检测为依赖

### 涉及文件

| 文件                         | 角色                                                                                      |
| ---------------------------- | ----------------------------------------------------------------------------------------- |
| `composables/useAuth.ts`     | **被修改文件** — 导出 `useAuth` 函数                                                      |
| `components/CartSummary.vue` | **依赖方** — `import { useAuth } from '~/composables/useAuth'`                            |
| `pages/index.vue`            | **auto-import 消费者** — 使用 `useAuth()` 但无显式 import（见场景 2 的 auto-import 机制） |

### 代码修改方式

修改 `composables/useAuth.ts`，为 `useAuth` 函数增加一个参数：

```diff
- export function useAuth() {
+ export function useAuth(options?: { redirectOnLogout?: boolean }) {
```

### 预期结果

- **Cross-file dependency analysis** 显示 `composables/useAuth.ts` 的 Modified exports: `useAuth (function)`
- **Referenced by** 列表包含 `components/CartSummary.vue → useAuth`
- 行内 review 评论列出受影响的调用方

---

## 场景 2: Composable Auto-Import (Nuxt 约定)

### 测试点

- Nuxt `composables/` 目录下的导出被 `.vue` 文件**无需 import 直接使用**
- 步骤 5.1 的 auto-import 约定检测能捕获这种隐式依赖

### 涉及文件

| 文件                         | 角色                                                            |
| ---------------------------- | --------------------------------------------------------------- |
| `composables/useCart.ts`     | **被修改文件** — 导出 `useCart` 函数及 `CartItem` 类型          |
| `pages/cart.vue`             | **依赖方** — `<script setup>` 中直接调用 `useCart()`，无 import |
| `components/CartSummary.vue` | **依赖方** — `<script setup>` 中直接调用 `useCart()`，无 import |

### 代码修改方式

修改 `composables/useCart.ts`，修改 `removeItem` 的函数签名：

```diff
- function removeItem(id: string) {
-   items.value = items.value.filter(i => i.id !== id)
- }
+ function removeItem(id: string, silent: boolean = false) {
+   items.value = items.value.filter(i => i.id !== id)
+   if (!silent) console.log(`Removed item: ${id}`)
+ }
```

### 预期结果

- **Cross-file dependency analysis** 显示 `composables/useCart.ts` 的 Modified exports: `useCart (function)`
- **Referenced by** 列表包含：
  - `pages/cart.vue → useCart`（auto-import，无显式 import）
  - `components/CartSummary.vue → useCart`（auto-import，无显式 import）

### 关键验证

> 此场景验证 **步骤 5.1** 的 auto-import 检测。传统 import 分析无法捕获此依赖。

---

## 场景 3: 工具函数引用

### 测试点

- `utils/` 目录下的工具函数被多个 `.vue` 文件显式导入
- `.vue` 文件中的 import 路径使用 `~/` 别名能正确解析

### 涉及文件

| 文件                         | 角色                                                             |
| ---------------------------- | ---------------------------------------------------------------- |
| `utils/formatPrice.ts`       | **被修改文件** — 导出 `formatPrice` 函数                         |
| `components/ProductCard.vue` | **依赖方** — `import { formatPrice } from '~/utils/formatPrice'` |
| `components/CartSummary.vue` | **依赖方** — `import { formatPrice } from '~/utils/formatPrice'` |
| `pages/products/[id].vue`    | **依赖方** — `import { formatPrice } from '~/utils/formatPrice'` |

### 代码修改方式

修改 `utils/formatPrice.ts`，增加默认参数：

```diff
  export function formatPrice(
    amount: number,
-   currency: string = 'CNY',
+   currency: string = 'USD',
    locale: string = 'zh-CN'
  ): string {
```

### 预期结果

- **Referenced by** 列表包含 3 个文件，均通过 `~/` 别名导入
- 行内 review 指出默认货币从 CNY 改为 USD 对调用方的影响

---

## 场景 4: 组件导入

### 测试点

- `.vue` 组件之间的**显式导入**（非 Nuxt auto-import 组件）
- 修改子组件的 `defineProps` 时，父组件被检测为依赖

### 涉及文件

| 文件                           | 角色                                                                   |
| ------------------------------ | ---------------------------------------------------------------------- |
| `components/ui/BaseButton.vue` | **被修改文件** — `defineProps` 定义组件接口                            |
| `components/ProductCard.vue`   | **依赖方** — `import BaseButton from '~/components/ui/BaseButton.vue'` |
| `components/CartSummary.vue`   | **依赖方** — `import BaseButton from '~/components/ui/BaseButton.vue'` |

### 代码修改方式

修改 `components/ui/BaseButton.vue`，给 `defineProps` 增加一个必需属性：

```diff
  const props = defineProps<{
    variant?: 'primary' | 'secondary' | 'danger'
    disabled?: boolean
+   size: 'sm' | 'md' | 'lg'
  }>()
```

### 预期结果

- **Modified exports** 包含 `props (variable)`（Vue 宏提取）
- **Referenced by** 列表包含 `ProductCard.vue` 和 `CartSummary.vue`

### 关键验证

> 此场景验证 **Vue 编译器宏** 的符号提取（`defineProps`）以及 `.vue` 到 `.vue` 的导入路径解析。

---

## 场景 5: Pinia Store 引用

### 测试点

- Pinia store 文件被 composable **显式导入**
- `.ts` 到 `.ts` 的标准 TS import 分析

### 涉及文件

| 文件                     | 角色                                                             |
| ------------------------ | ---------------------------------------------------------------- |
| `stores/userStore.ts`    | **被修改文件** — 导出 `useUserStore` 和 `User` 类型              |
| `composables/useAuth.ts` | **依赖方** — `import { useUserStore } from '~/stores/userStore'` |

### 代码修改方式

修改 `stores/userStore.ts`，给 `User` 接口增加字段：

```diff
  export interface User {
    email: string
    name: string
+   avatar?: string
  }
```

### 预期结果

- **Modified exports** 包含 `useUserStore (variable)`（通过 `export const`）
- **Referenced by** 列表包含 `composables/useAuth.ts → useUserStore`

---

## 场景 6: Nuxt Extends 层 — Composable

### 测试点

- **base-layer** 中 `composables/` 下的导出通过 Nuxt extends 机制被主项目使用
- auto-import 检测能跨 layer 边界追踪（因为 `base-layer/composables/` 匹配 auto-import 源路径）

### 涉及文件

| 文件                                  | 角色                                                      |
| ------------------------------------- | --------------------------------------------------------- |
| `base-layer/composables/useTheme.ts`  | **被修改文件** — 导出 `useTheme` 函数                     |
| `layouts/default.vue`                 | **依赖方** — `<script setup>` 中 auto-import `useTheme()` |
| `components/ProductCard.vue`          | **依赖方** — `<script setup>` 中 auto-import `useTheme()` |
| `base-layer/components/AppHeader.vue` | **依赖方** — `<script setup>` 中 auto-import `useTheme()` |

### 代码修改方式

修改 `base-layer/composables/useTheme.ts`，增加返回值：

```diff
- return { isDark, toggleTheme }
+ const themeColor = computed(() => isDark.value ? '#1a1a1a' : '#ffffff')
+ return { isDark, toggleTheme, themeColor }
```

### 预期结果

- **Cross-file dependency analysis** 显示 `base-layer/composables/useTheme.ts`
- **Referenced by** 列表包含跨层引用的文件

### 关键验证

> 此场景验证 `isNuxtAutoImportSource()` 的正则 `/\/(composables|utils|components|stores)\//` 能匹配 `base-layer/composables/` 路径。

---

## 场景 7: Nuxt Extends 层 — 组件

### 测试点

- base-layer 的组件被 Nuxt 自动注册后，在主项目 template 中使用
- `.vue` 组件的 `defineEmits` 宏能被提取为修改符号

### 涉及文件

| 文件                                  | 角色                                                                  |
| ------------------------------------- | --------------------------------------------------------------------- |
| `base-layer/components/AppHeader.vue` | **被修改文件** — base-layer 头部组件                                  |
| `layouts/default.vue`                 | **依赖方** — template 中使用 `<AppHeader />`（Nuxt auto-import 组件） |

### 代码修改方式

修改 `base-layer/components/AppHeader.vue`，增加 `defineEmits`：

```diff
  <script setup lang="ts">
  const { isDark } = useTheme()
+ const emit = defineEmits<{
+   menuToggle: [open: boolean]
+ }>()
  </script>
```

### 预期结果

- **Modified exports** 包含 `emit (variable)`
- 由于 `layouts/default.vue` 在 template 中使用 `<AppHeader />`，但在 `<script>` 中不直接引用该符号，此场景主要验证宏提取

### 注意

> 组件在 template 中的使用（`<AppHeader />`）不通过 JS import 追踪，而是通过 Nuxt 的组件自动注册。当前实现基于 `<script>` 块内的符号搜索。

---

## 场景 8: Nuxt Extends 层 — 工具函数

### 测试点

- base-layer 中 `utils/` 下的工具函数被主项目**显式 import**（非 auto-import）
- 路径使用 `~/base-layer/utils/logger` 形式的别名

### 涉及文件

| 文件                         | 角色                                                               |
| ---------------------------- | ------------------------------------------------------------------ |
| `base-layer/utils/logger.ts` | **被修改文件** — 导出 `logInfo`、`logError`、`logWarn`             |
| `composables/useAuth.ts`     | **依赖方** — `import { logInfo } from '~/base-layer/utils/logger'` |
| `stores/userStore.ts`        | **依赖方** — `import { logInfo } from '~/base-layer/utils/logger'` |

### 代码修改方式

修改 `base-layer/utils/logger.ts`，修改 `logInfo` 函数签名：

```diff
- export function logInfo(message: string, context?: Record<string, unknown>): void {
+ export function logInfo(message: string, context?: Record<string, unknown>, tags?: string[]): void {
    const timestamp = new Date().toISOString()
-   const contextStr = context ? ` ${JSON.stringify(context)}` : ''
-   console.log(`[INFO] ${timestamp} ${message}${contextStr}`)
+   const contextStr = context ? ` ${JSON.stringify(context)}` : ''
+   const tagStr = tags?.length ? ` [${tags.join(',')}]` : ''
+   console.log(`[INFO] ${timestamp}${tagStr} ${message}${contextStr}`)
  }
```

### 预期结果

- **Modified exports** 包含 `logInfo (function)`
- **Referenced by** 列表包含：
  - `composables/useAuth.ts → logInfo`
  - `stores/userStore.ts → logInfo`
- 行内 review 指出新增的 `tags` 参数为可选，现有调用方不受影响

### 关键验证

> 此场景验证跨 layer 的**显式 import** 路径解析（`~/base-layer/utils/logger`）。

---

## 场景 9: 异步组件 — defineAsyncComponent + 动态 import()

### 测试点

- `defineAsyncComponent(() => import('./path'))` 中的静态字符串路径能被解析
- 带 `options.loader` 形式的 `defineAsyncComponent` 也能被解析
- 异步导入的路径使用 `~/` 别名能正确解析

### 涉及文件

| 文件                               | 角色                                                                                            |
| ---------------------------------- | ----------------------------------------------------------------------------------------------- |
| `components/HeavyChart.vue`        | **被修改文件** — 重型图表组件                                                                   |
| `components/ReviewPanel.vue`       | **被修改文件** — 评价面板组件                                                                   |
| `pages/dashboard.vue`              | **依赖方** — `defineAsyncComponent(() => import('~/components/HeavyChart.vue'))`                |
| `components/DynamicPathImport.vue` | **依赖方** — `defineAsyncComponent(() => import('~/components/HeavyChart.vue'))` (静态路径部分) |

### 代码修改方式

修改 `components/HeavyChart.vue`，给 `defineProps` 增加必需属性：

```diff
  const props = defineProps<{
    data: number[]
    title: string
    color?: string
+   animate?: boolean
  }>()
```

### 预期结果

- **Modified exports** 包含 `props (variable)`
- **Referenced by** 列表包含：
  - `pages/dashboard.vue` — 通过 `defineAsyncComponent(() => import('~/components/HeavyChart.vue'))` 建立依赖
  - `components/DynamicPathImport.vue` — 通过静态路径 `import('~/components/HeavyChart.vue')` 建立依赖

### 关键验证

> 此场景验证 `parseTsImports` 中新增的 **动态 `import()` 正则** 能匹配 `defineAsyncComponent` 内的静态字符串路径。

---

## 场景 10: 动态组件 — `<component :is>` 使用导入的组件引用

### 测试点

- `<component :is="variable">` 中 `variable` 来自 `import` 语句时，依赖关系通过 import 建立
- 虽然 template 中使用动态渲染，但 `<script>` 中的 import 已被解析

### 涉及文件

| 文件                             | 角色                                                                                                                                                                    |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `components/ProductCard.vue`     | **被修改文件** — 产品卡片组件                                                                                                                                           |
| `components/HeavyChart.vue`      | **被修改文件** — 重型图表组件                                                                                                                                           |
| `components/DynamicRenderer.vue` | **依赖方** — `import ProductCard from '~/components/ProductCard.vue'` + `import HeavyChart from '~/components/HeavyChart.vue'`，在 template 中用 `<component :is>` 渲染 |

### 代码修改方式

修改 `components/ProductCard.vue`，增加一个 prop：

```diff
  const props = defineProps<{
    id: string
    name: string
    price: number
    image: string
+   badge?: string
  }>()
```

### 预期结果

- **Referenced by** 列表包含 `components/DynamicRenderer.vue → ProductCard`
- 依赖关系通过 `import ProductCard from '~/components/ProductCard.vue'` 建立，而非 template 中的 `<component :is>`

### 关键验证

> 此场景验证：动态组件 `<component :is>` 的常见用法（import 后传入）**可以被正常追踪**，因为依赖关系本质上由 import 语句建立。

---

## 场景 11 (已知限制): 运行时动态 `<component :is>` — 无法检测

### 测试点

- `<component :is="resolveComponent(variable)">` 没有 import 语句，依赖关系无法建立
- 确认此场景**不会被检测到**是预期行为

### 涉及文件

| 文件                            | 角色                                                                                      |
| ------------------------------- | ----------------------------------------------------------------------------------------- |
| `components/HeavyChart.vue`     | **被修改文件**                                                                            |
| `components/RuntimeDynamic.vue` | **不会被检测为依赖** — 使用 `resolveComponent(props.componentName)` 运行时解析，无 import |

### 对照代码

**RuntimeDynamic.vue** — 无法检测的写法：

```vue
<script setup lang="ts">
const props = defineProps<{ componentName: string }>()
// ❌ 运行时 resolveComponent，无 import 语句 — 无法被静态分析
const dynamicComp = computed(() => resolveComponent(props.componentName))
</script>
<template>
  <component :is="dynamicComp" />
</template>
```

**DynamicRenderer.vue** — 可以检测的写法：

```vue
<script setup lang="ts">
import ProductCard from "~/components/ProductCard.vue" // ✅ import 建立依赖
import HeavyChart from "~/components/HeavyChart.vue" // ✅ import 建立依赖

const widgetMap = { product: ProductCard, chart: HeavyChart }
const currentWidget = computed(() => widgetMap[props.type])
</script>
<template>
  <component :is="currentWidget" />
</template>
```

### 预期结果

- 修改 `HeavyChart.vue` 时，`RuntimeDynamic.vue` **不会出现**在 Referenced by 列表中
- 修改 `HeavyChart.vue` 时，`DynamicRenderer.vue` **会出现**在 Referenced by 列表中

---

## 场景 12 (已知限制): 动态路径 `import()` — 模板字符串无法解析

### 测试点

- `import(\`~/components/${variable}.vue\`)` 路径包含变量，无法静态分析
- 同一文件中的静态路径 `import('~/components/HeavyChart.vue')` 能被正常解析

### 涉及文件

| 文件                               | 角色                                                  |
| ---------------------------------- | ----------------------------------------------------- |
| `components/HeavyChart.vue`        | **被修改文件**                                        |
| `components/DynamicPathImport.vue` | **部分检测** — 静态路径可检测，模板字符串路径不可检测 |

### 对照代码

**DynamicPathImport.vue**：

```vue
<script setup lang="ts">
import { defineAsyncComponent } from "vue"

// ❌ 模板字符串路径 — 无法解析
const DynamicWidget = defineAsyncComponent(() => import(`~/components/${props.widgetName}.vue`))

// ✅ 静态字符串路径 — 可以解析
const StaticWidget = defineAsyncComponent(() => import("~/components/HeavyChart.vue"))
</script>
```

### 预期结果

- 修改 `HeavyChart.vue` 时，`DynamicPathImport.vue` **会出现**在 Referenced by 列表中（因为静态路径 `import('~/components/HeavyChart.vue')` 被解析）
- 但如果只有模板字符串路径而无静态路径，则无法检测

---
