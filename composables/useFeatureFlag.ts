interface FeatureFlags {
  enableNewCheckout: boolean
  enableDarkMode: boolean
  enableWebSocket: boolean
  maxCartItems: number
}

const DEFAULT_FLAGS: FeatureFlags = {
  enableNewCheckout: false,
  enableDarkMode: true,
  enableWebSocket: false,
  maxCartItems: 99
}

export const useFeatureFlag = () => {
  const flags = useState<FeatureFlags>('feature-flags', () => ({ ...DEFAULT_FLAGS }))
  const loaded = useState('feature-flags-loaded', () => false)

  const isEnabled = (flag: keyof FeatureFlags): boolean => {
    const value = flags.value[flag]
    return typeof value === 'boolean' ? value : false
  }

  const fetchFlags = async () => {
    if (loaded.value) return
    try {
      const response = await $fetch<FeatureFlags>('/api/feature-flags')
      flags.value = response
      loaded.value = true
    } catch {
      console.warn('Failed to fetch feature flags, using defaults')
      flags.value = { ...DEFAULT_FLAGS }
    }
  }

  return { flags, isEnabled, fetchFlags }
}
