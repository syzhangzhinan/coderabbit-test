const dateFormatter = new Intl.DateTimeFormat('zh-CN', { dateStyle: 'short' })
const dateTimeFormatter = new Intl.DateTimeFormat('zh-CN', { dateStyle: 'short', timeStyle: 'short' })

export const formatDate = (date: string | Date): string => {
  return dateFormatter.format(new Date(date))
}

export const formatDateTime = (date: string | Date): string => {
  return dateTimeFormatter.format(new Date(date))
}

const rtf = new Intl.RelativeTimeFormat('zh-CN', { numeric: 'auto' })

export const timeAgo = (date: string | Date): string => {
  const now = Date.now()
  const past = new Date(date).getTime()
  const diffSeconds = Math.floor((now - past) / 1000)

  if (diffSeconds < 60) return rtf.format(-diffSeconds, 'second')
  if (diffSeconds < 3600) return rtf.format(-Math.floor(diffSeconds / 60), 'minute')
  if (diffSeconds < 86400) return rtf.format(-Math.floor(diffSeconds / 3600), 'hour')
  return rtf.format(-Math.floor(diffSeconds / 86400), 'day')
}
