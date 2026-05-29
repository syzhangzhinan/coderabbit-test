import { describe, it, expect, vi } from "vitest"
import { ref } from "vue"

// useState is a Nuxt auto-import global — stub it to use Vue's ref internally
vi.stubGlobal("useState", (_key: string, init: () => unknown) => ref(init()))

import { useTheme } from "../base-layer/composables/useTheme"

describe("useTheme", () => {
  describe("initial state", () => {
    it("isDark defaults to false", () => {
      const { isDark } = useTheme()
      expect(isDark.value).toBe(false)
    })
  })

  describe("toggleTheme", () => {
    it("flips isDark from false to true", () => {
      const { isDark, toggleTheme } = useTheme()
      expect(isDark.value).toBe(false)
      toggleTheme()
      expect(isDark.value).toBe(true)
    })

    it("flips isDark from true back to false", () => {
      const { isDark, toggleTheme } = useTheme()
      toggleTheme() // false → true
      toggleTheme() // true → false
      expect(isDark.value).toBe(false)
    })

    it("toggles multiple times correctly", () => {
      const { isDark, toggleTheme } = useTheme()
      for (let i = 1; i <= 5; i++) {
        toggleTheme()
        expect(isDark.value).toBe(i % 2 === 1)
      }
    })
  })

  describe("return shape", () => {
    it("returns isDark and toggleTheme", () => {
      const result = useTheme()
      expect(result).toHaveProperty("isDark")
      expect(result).toHaveProperty("toggleTheme")
      expect(typeof result.toggleTheme).toBe("function")
    })

    it("isDark is a ref (has .value property)", () => {
      const { isDark } = useTheme()
      expect(isDark).toHaveProperty("value")
    })
  })
})