<script setup lang="ts">
/**
 * 运行时动态组件 — 已知限制示例
 *
 * 测试场景 11 (限制): 运行时动态 <component :is> 无法被检测
 *
 * 此文件中没有对 HeavyChart 或 ReviewPanel 的 import 语句，
 * 组件名通过 resolveComponent() 在运行时解析，
 * 因此依赖分析无法建立依赖关系。
 */

const props = defineProps<{
  componentName: string
}>()

// 限制: 运行时 resolveComponent — 无法静态分析
const dynamicComp = computed(() => resolveComponent(props.componentName))
</script>

<template>
  <div class="runtime-dynamic">
    <!-- 限制: :is 绑定到运行时计算值，无 import 语句 -->
    <component :is="dynamicComp" />
  </div>
</template>
