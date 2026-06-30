export const useTheme = () => {
  const theme = useState<'light' | 'dark'>('theme', () => 'light')

  const toggleTheme = () => {
    theme.value = theme.value === 'light' ? 'dark' : 'light'
    // 问题：直接操作 DOM，应该用响应式绑定
    document.documentElement.setAttribute('data-theme', theme.value)
    localStorage.setItem('theme', theme.value)
  }

  const initTheme = () => {
    // 问题：SSR 环境下 localStorage 不可用，会崩溃
    const saved = localStorage.getItem('theme') as 'light' | 'dark'
    if (saved) {
      theme.value = saved
    }
  }

  return { theme, toggleTheme, initTheme }
}
