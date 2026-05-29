<script setup lang="ts">
/**
 * 仪表盘页面
 *
 * 测试场景 9: 使用 defineAsyncComponent 异步导入 HeavyChart 和 ReviewPanel
 */
import { defineAsyncComponent } from 'vue'

// defineAsyncComponent + 动态 import() — 异步加载重型组件
const AsyncChart = defineAsyncComponent(() => import('~/components/HeavyChart.vue'))

// 带 options 的 defineAsyncComponent
const AsyncReviewPanel = defineAsyncComponent({
  loader: () => import('~/components/ReviewPanel.vue'),
  delay: 200
})

const chartData = ref([30, 60, 45, 80, 55, 70, 90])
const reviews = ref([
  { id: '1', author: '张三', rating: 5, content: '非常好用' },
  { id: '2', author: '李四', rating: 4, content: '还不错' }
])
</script>

<template>
  <div class="page-dashboard">
    <h1>数据面板</h1>
    <AsyncChart :data="chartData" title="销售趋势" />
    <AsyncReviewPanel :reviews="reviews" />
  </div>
</template>
