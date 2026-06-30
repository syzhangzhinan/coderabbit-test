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
const { pause, resume } = useIntervalFn(fetchStats, 30000)

async function fetchStats() {
  try {
    stats.value = await $fetch<Stat[]>('/api/dashboard/stats')
  } catch {
    // keep previous stats on failure
  }
}

onMounted(fetchStats)
onUnmounted(pause)
</script>

<style scoped>
.dashboard-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}
.stat-card {
  padding: 1.5rem;
  background: white;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  display: flex;
  flex-direction: column;
  align-items: center;
}
.stat-value { font-size: 2rem; font-weight: bold; color: #3b82f6; }
.stat-label { color: #6b7280; margin-top: 0.5rem; }
</style>
