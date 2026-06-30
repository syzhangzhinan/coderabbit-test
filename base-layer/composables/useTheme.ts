export const useTheme = () => {
  const theme = useState<'light' | 'dark'>('theme', () => 'light')

  const toggleTheme = () => {
    theme.value = theme.value === 'light' ? 'dark' : 'light'
  }

  const initTheme = () => {
    if (import.meta.client) {
      const saved = localStorage.getItem('theme') as 'light' | 'dark' | null
      if (saved) {
        theme.value = saved
      }
      watch(theme, (val) => {
        document.documentElement.setAttribute('data-theme', val)
        localStorage.setItem('theme', val)
      }, { immediate: true })
    }
  }

  return { theme, toggleTheme, initTheme }
}
