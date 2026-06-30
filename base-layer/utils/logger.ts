type LogLevel = 'debug' | 'info' | 'warn' | 'error'

interface LogEntry {
  level: LogLevel
  message: string
  timestamp: number
}

export const createLogger = (prefix: string = '') => {
  const history: LogEntry[] = []

  const log = (level: LogLevel, message: string) => {
    const entry: LogEntry = { level, message, timestamp: Date.now() }
    history.push(entry)

    if (import.meta.dev) {
      const tag = prefix ? `[${prefix}]` : ''
      console[level](`${tag}[${level.toUpperCase()}] ${message}`)
    }
  }

  return {
    debug: (msg: string) => log('debug', msg),
    info: (msg: string) => log('info', msg),
    warn: (msg: string) => log('warn', msg),
    error: (msg: string) => log('error', msg),
    getHistory: () => [...history],
    clear: () => { history.length = 0 }
  }
}

export const logger = createLogger()
