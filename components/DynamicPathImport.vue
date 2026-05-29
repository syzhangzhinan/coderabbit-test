<script setup lang="ts">
/**
 * 动态路径 import — 已知限制示例
 *
 * 测试场景 12 (限制): import(variable) 路径非字符串字面量，无法解析
 */
import { defineAsyncComponent } from 'vue'

const props = defineProps<{
  widgetName: string
}>()

// 限制: 模板字符串路径 — 变量部分无法静态分析
const DynamicWidget = defineAsyncComponent(
  () => import(`~/components/${props.widgetName}.vue`)
)

// 对比: 静态字符串路径 — 可以被解析
const StaticWidget = defineAsyncComponent(
  () => import('~/components/HeavyChart.vue')
)
</script>

<template>
  <div class="dynamic-path-import">
    <DynamicWidget />
    <StaticWidget />
  </div>
</template>
