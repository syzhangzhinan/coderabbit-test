<script setup lang="ts">
/**
 * 重型图表组件（被异步加载）
 *
 * 测试场景 9: 被 pages/dashboard.vue 通过 defineAsyncComponent 异步导入
 * 测试场景 10: 被 components/ProductCard.vue 通过动态 import() 引用
 */

const props = defineProps<{
  data: number[]
  title: string
  color?: string
}>()

const chartStyle = computed(() => ({
  "--chart-color": props.color ?? "#3b82f6"
}))
</script>

<template>
  <div class="heavy-chart" :style="chartStyle">
    <h3>{{ title }}</h3>
    <div class="chart-bars">
      <div
        v-for="(value, index) in data"
        :key="index"
        class="bar"
        :style="{ height: `${value}%` }"
      />
    </div>
  </div>
</template>
