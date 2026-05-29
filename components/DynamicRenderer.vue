<script setup lang="ts">
/**
 * 动态组件渲染器
 *
 * 测试场景 10: <component :is> 使用导入的组件引用
 * 测试场景 11 (限制): <component :is> 使用运行时字符串变量 — 无法被检测
 */
import ProductCard from '~/components/ProductCard.vue'
import HeavyChart from '~/components/HeavyChart.vue'

type WidgetType = 'product' | 'chart'

const props = defineProps<{
  type: WidgetType
}>()

// 场景 10: 通过 import 引用的组件 — 可被检测（import 语句建立依赖）
const widgetMap = {
  product: ProductCard,
  chart: HeavyChart
} as const

const currentWidget = computed(() => widgetMap[props.type])
</script>

<template>
  <div class="dynamic-renderer">
    <!-- 场景 10: 使用 import 引用的组件变量 — 依赖关系通过 import 建立 -->
    <component :is="currentWidget" v-bind="$attrs" />
  </div>
</template>
