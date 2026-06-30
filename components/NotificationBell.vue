<template>
  <div class="notification-bell" @click="togglePanel">
    <span class="bell-icon">🔔</span>
    <span v-if="unreadCount > 0" class="badge">{{ unreadCount }}</span>
    <div v-if="showPanel" class="notification-panel">
      <div v-for="notif in notifications" :key="notif.id" class="notif-item"
           :class="{ unread: !notif.read }"
           @click.stop="markAsRead(notif.id)">
        <p>{{ notif.message }}</p>
        <span class="notif-time">{{ notif.createdAt }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Notification {
  id: string
  message: string
  read: boolean
  createdAt: string
}

const showPanel = ref(false)
const notifications = ref<Notification[]>([])

const unreadCount = computed(() => notifications.value.filter(n => !n.read).length)

const togglePanel = () => {
  showPanel.value = !showPanel.value
}

const markAsRead = async (id: string) => {
  try {
    await $fetch(`/api/notifications/${id}/read`, { method: 'POST' })
    const notif = notifications.value.find(n => n.id === id)
    if (notif) notif.read = true
  } catch {
    // revert on failure — already unchanged since we update after success
  }
}

const connectWebSocket = () => {
  if (!import.meta.client) return
  const config = useRuntimeConfig()
  const wsUrl = `${config.public.apiBase.replace('http', 'ws')}/notifications`
  let ws: WebSocket | null = null
  let reconnectTimer: ReturnType<typeof setTimeout> | null = null

  const connect = () => {
    ws = new WebSocket(wsUrl)
    ws.onmessage = (event) => {
      const notif = JSON.parse(event.data) as Notification
      notifications.value.unshift(notif)
    }
    ws.onclose = () => {
      reconnectTimer = setTimeout(connect, 5000)
    }
  }

  connect()
  onUnmounted(() => {
    ws?.close()
    if (reconnectTimer) clearTimeout(reconnectTimer)
  })
}

onMounted(connectWebSocket)
</script>

<style scoped>
.notification-bell { position: relative; cursor: pointer; }
.badge {
  position: absolute; top: -5px; right: -5px;
  background: #ef4444; color: white; border-radius: 50%;
  width: 18px; height: 18px; font-size: 0.75rem;
  display: flex; align-items: center; justify-content: center;
}
.notification-panel {
  position: absolute; top: 100%; right: 0; width: 300px;
  background: white; border: 1px solid #e5e7eb; border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15); max-height: 400px;
  overflow-y: auto; z-index: 100;
}
.notif-item { padding: 0.75rem; border-bottom: 1px solid #f3f4f6; }
.notif-item.unread { background: #eff6ff; }
</style>
