<script setup lang="ts">
/**
 * 基础按钮组件
 *
 * 测试场景 4: 被 ProductCard.vue 和 CartSummary.vue 显式导入
 */
const props = defineProps<{
  variant?: "primary" | "secondary" | "danger"
  disabled?: boolean
  // size: "sm" | "md" | "lg"
}>()

const emit = defineEmits<{
  click: [event: MouseEvent]
}>()

const classes = computed(() => [
  "base-button",
  `base-button--${props.variant ?? "primary"}`,
  { "base-button--disabled": props.disabled }
])
</script>

<template>
  <button :class="classes" :disabled="disabled" @click="emit('click', $event)">
    <slot />
  </button>
</template>
