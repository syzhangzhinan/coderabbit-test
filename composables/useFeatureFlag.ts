import { logInfo, logWarn } from "~/base-layer/utils/logger"
import { getFeatureFlags } from "~/stores/userStore"

export function useFeatureFlag(flag: string) {
  const flags = getFeatureFlags()
  if (flag in flags) {
    logInfo("[feature-flag] hit", { flag })
    return flags[flag]
  }
  logWarn("[feature-flag] miss", { flag })
  return false
}
