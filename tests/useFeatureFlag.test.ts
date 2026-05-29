import { describe, it, expect, vi, beforeEach } from "vitest"

// Mock dependencies before importing the composable
vi.mock("~/base-layer/utils/logger", () => ({
  logInfo: vi.fn(),
  logWarn: vi.fn(),
}))

const mockGetFeatureFlags = vi.fn<() => Record<string, boolean>>()

vi.mock("~/stores/userStore", () => ({
  getFeatureFlags: () => mockGetFeatureFlags(),
}))

import { useFeatureFlag } from "../composables/useFeatureFlag"
import { logInfo, logWarn } from "../base-layer/utils/logger"

describe("useFeatureFlag", () => {
  beforeEach(() => {
    vi.mocked(logInfo).mockClear()
    vi.mocked(logWarn).mockClear()
    mockGetFeatureFlags.mockClear()
  })

  describe("when flag exists in the feature flags object", () => {
    it("returns the flag value (true)", () => {
      mockGetFeatureFlags.mockReturnValue({ "new-ui": true })
      expect(useFeatureFlag("new-ui")).toBe(true)
    })

    it("returns the flag value (false)", () => {
      mockGetFeatureFlags.mockReturnValue({ "beta-feature": false })
      expect(useFeatureFlag("beta-feature")).toBe(false)
    })

    it("calls logInfo with hit message and flag name", () => {
      mockGetFeatureFlags.mockReturnValue({ "my-flag": true })
      useFeatureFlag("my-flag")
      expect(logInfo).toHaveBeenCalledWith("[feature-flag] hit", { flag: "my-flag" })
    })

    it("does not call logWarn when flag is found", () => {
      mockGetFeatureFlags.mockReturnValue({ "existing-flag": true })
      useFeatureFlag("existing-flag")
      expect(logWarn).not.toHaveBeenCalled()
    })
  })

  describe("when flag does not exist in the feature flags object", () => {
    it("returns false", () => {
      mockGetFeatureFlags.mockReturnValue({ "other-flag": true })
      expect(useFeatureFlag("missing-flag")).toBe(false)
    })

    it("returns false when flags object is empty", () => {
      mockGetFeatureFlags.mockReturnValue({})
      expect(useFeatureFlag("any-flag")).toBe(false)
    })

    it("calls logWarn when flag is missing", () => {
      mockGetFeatureFlags.mockReturnValue({})
      useFeatureFlag("unknown-flag")
      expect(logWarn).toHaveBeenCalled()
    })

    it("does not call logInfo when flag is missing", () => {
      mockGetFeatureFlags.mockReturnValue({})
      useFeatureFlag("missing")
      expect(logInfo).not.toHaveBeenCalled()
    })
  })

  describe("multiple flags", () => {
    it("returns correct value for each queried flag", () => {
      mockGetFeatureFlags.mockReturnValue({
        "flag-a": true,
        "flag-b": false,
        "flag-c": true,
      })
      expect(useFeatureFlag("flag-a")).toBe(true)
      expect(useFeatureFlag("flag-b")).toBe(false)
      expect(useFeatureFlag("flag-c")).toBe(true)
    })

    it("returns false for a flag not in the set", () => {
      mockGetFeatureFlags.mockReturnValue({ "flag-a": true })
      expect(useFeatureFlag("flag-x")).toBe(false)
    })
  })

  describe("calls getFeatureFlags on every invocation", () => {
    it("calls getFeatureFlags each time useFeatureFlag is called", () => {
      mockGetFeatureFlags.mockReturnValue({ "flag": true })
      useFeatureFlag("flag")
      useFeatureFlag("flag")
      expect(mockGetFeatureFlags).toHaveBeenCalledTimes(2)
    })
  })
})