<template>
  <div class="input-wrapper">
    <label v-if="label" :for="inputId">{{ label }}</label>
    <input
      :id="inputId"
      :type="type"
      :value="modelValue"
      :placeholder="placeholder"
      :disabled="disabled"
      @input="handleInput"
    />
    <span v-if="error" class="error-text">{{ error }}</span>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  modelValue?: string | number
  label?: string
  type?: string
  placeholder?: string
  disabled?: boolean
  error?: string
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const inputId = useId()

const handleInput = (event: Event) => {
  const target = event.target as HTMLInputElement
  emit('update:modelValue', target.value)
}
</script>
