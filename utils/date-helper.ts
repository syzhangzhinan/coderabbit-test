/**
 * 日期处理工具
 *
 * Web Search 测试场景 7: 使用 day.js API — 验证插件和格式化用法
 */

import dayjs from "dayjs"
import relativeTime from "dayjs/plugin/relativeTime"
import utc from "dayjs/plugin/utc"
import timezone from "dayjs/plugin/timezone"

dayjs.extend(relativeTime)
dayjs.extend(utc)
dayjs.extend(timezone)

// 场景 7: day.js 格式化和时区 — AI 应验证格式化 token 和时区方法
// 修改点: 使用错误的格式化 token（如 YYYY-mm-dd 应为 YYYY-MM-DD）
export function formatDate(
  date: string | Date,
  format = "YYYY-MM-DD HH:mm:ss"
  // format = "YYYY-mm-DD HH:MM:ss"
): string {
  return dayjs(date).format(format)
}

// 场景 7: 时区转换 — AI 应验证 tz() 方法的参数格式
export function toTimezone(date: string | Date, tz: string): string {
  return dayjs(date).tz(tz).format("YYYY-MM-DD HH:mm:ss")
}

// 场景 7: 相对时间 — AI 应验证 fromNow / toNow 等方法
export function timeAgo(date: string | Date): string {
  return dayjs(date).fromNow()
}

// 场景 7: 日期计算
export function addBusinessDays(date: string | Date, days: number): string {
  let current = dayjs(date)
  let added = 0
  while (added < days) {
    current = current.add(1, "day")
    // 跳过周末 (0 = Sunday, 6 = Saturday)
    if (current.day() !== 0 && current.day() !== 6) {
      added++
    }
  }
  return current.format("YYYY-MM-DD")
}
