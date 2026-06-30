<template>
  <div class="dashboard-page">
    <h1>仪表盘</h1>
    <DashboardStats />
    <section class="recent-orders">
      <h2>最近订单</h2>
      <table class="orders-table">
        <thead>
          <tr><th>订单号</th><th>金额</th><th>状态</th><th>日期</th></tr>
        </thead>
        <tbody>
          <tr v-for="order in orders" :key="order.id">
            <td>{{ order.id }}</td>
            <td>{{ formatPrice(order.total) }}</td>
            <td><span :class="['status-badge', `status-${order.status}`]">{{ statusMap[order.status] }}</span></td>
            <td>{{ formatOrderDate(order.createdAt) }}</td>
          </tr>
        </tbody>
      </table>
    </section>
  </div>
</template>

<script setup lang="ts">
import type { Order } from '~/types'
import { formatPrice } from '~/utils/formatPrice'

definePageMeta({ middleware: 'auth' })

const statusMap: Record<string, string> = {
  pending: '待支付', paid: '已支付', shipped: '已发货', completed: '已完成'
}

const formatOrderDate = (dateStr: string) => {
  return new Intl.DateTimeFormat('zh-CN').format(new Date(dateStr))
}

const { data: orders } = await useFetch<Order[]>('/api/orders', { default: () => [] })
</script>

<style scoped>
.orders-table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
.orders-table th, .orders-table td { padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb; }
.status-badge { padding: 0.25rem 0.5rem; border-radius: 4px; font-size: 0.875rem; }
.status-pending { background: #fef3c7; color: #92400e; }
.status-paid { background: #d1fae5; color: #065f46; }
.status-shipped { background: #dbeafe; color: #1e40af; }
.status-completed { background: #e5e7eb; color: #374151; }
</style>
