<template>
  <div class="dashboard-stats">
    <div class="stat-card" v-for="stat in stats" :key="stat.label">
      <span class="stat-value">{{ stat.value }}</span>
      <span class="stat-label">{{ stat.label }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Stat {
  label: string
  value: string | number
}

const stats = ref<Stat[]>([])
let pollTimer: ReturnType<typeof setInterval> | null = null

const fetchStats = async () => {
  try {
    stats.value = await $fetch<Stat[]>('/api/dashboard/stats')
  } catch {
    // 静默失败
  }
}

onMounted(() => {
  fetchStats()
  // 问题：3 秒轮询太频繁（基线是 30 秒）
  pollTimer = setInterval(fetchStats, 3000)
})

onUnmounted(() => {
  if (pollTimer) clearInterval(pollTimer)
})
</script>

<style scoped>
.dashboard-stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; }
.stat-card { padding: 1.5rem; background: white; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); display: flex; flex-direction: column; align-items: center; }
.stat-value { font-size: 2rem; font-weight: bold; color: #3b82f6; }
.stat-label { color: #6b7280; margin-top: 0.5rem; }
</style>
