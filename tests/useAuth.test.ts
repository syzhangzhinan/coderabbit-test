import { describe, it, expect, vi, beforeEach } from "vitest"
import { ref, computed } from "vue"

// Stub Nuxt auto-import globals before importing the composable
vi.stubGlobal("computed", computed)
vi.stubGlobal("navigateTo", vi.fn())

// Mock the logger module
vi.mock("~/base-layer/utils/logger", () => ({
  logInfo: vi.fn(),
}))

// Pinia stores auto-unwrap reactive refs — replicate this with a reactive mock
// using a getter so `userStore.currentUser` returns the unwrapped value (User | null),
// not the raw ref object.
const _currentUser = ref<{ email: string; name: string } | null>(null)
const mockSetUser = vi.fn(async (user: { email: string; name: string }) => {
  _currentUser.value = user
})
const mockClearUser = vi.fn(() => {
  _currentUser.value = null
})

vi.mock("~/stores/userStore", () => ({
  useUserStore: () =>
    new Proxy(
      {},
      {
        get(_, prop) {
          if (prop === "currentUser") return _currentUser.value
          if (prop === "setUser") return mockSetUser
          if (prop === "clearUser") return mockClearUser
        },
      }
    ),
}))

import { useAuth } from "../composables/useAuth"
import { logInfo } from "../base-layer/utils/logger"

describe("useAuth", () => {
  beforeEach(() => {
    _currentUser.value = null
    mockSetUser.mockClear()
    mockClearUser.mockClear()
    vi.mocked(logInfo).mockClear()
    vi.mocked(globalThis.navigateTo as ReturnType<typeof vi.fn>).mockClear()
  })

  describe("isLoggedIn", () => {
    it("is false when currentUser is null", () => {
      const { isLoggedIn } = useAuth()
      expect(isLoggedIn.value).toBe(false)
    })

    it("is true when currentUser is set", () => {
      _currentUser.value = { email: "user@example.com", name: "user" }
      const { isLoggedIn } = useAuth()
      expect(isLoggedIn.value).toBe(true)
    })

    it("reflects reactive changes to currentUser", () => {
      const { isLoggedIn } = useAuth()
      expect(isLoggedIn.value).toBe(false)
      _currentUser.value = { email: "test@test.com", name: "test" }
      expect(isLoggedIn.value).toBe(true)
      _currentUser.value = null
      expect(isLoggedIn.value).toBe(false)
    })
  })

  describe("login", () => {
    it("calls logInfo with login attempt and email", async () => {
      const { login } = useAuth()
      await login("alice@example.com", "secret")
      expect(logInfo).toHaveBeenCalledWith("login attempt", { email: "alice@example.com" })
    })

    it("calls userStore.setUser with email and derived name", async () => {
      const { login } = useAuth()
      await login("alice@example.com", "secret")
      expect(mockSetUser).toHaveBeenCalledWith({
        email: "alice@example.com",
        name: "alice",
      })
    })

    it("derives name from email by taking part before @", async () => {
      const { login } = useAuth()
      await login("bob.smith@domain.org", "pw")
      expect(mockSetUser).toHaveBeenCalledWith({
        email: "bob.smith@domain.org",
        name: "bob.smith",
      })
    })

    it("sets up sessionTimeout when option is provided", async () => {
      vi.useFakeTimers()
      const { login } = useAuth({ sessionTimeout: 1000 })
      await login("user@test.com", "pw")
      // The setTimeout calls logout internally — verify timer is scheduled
      expect(vi.getTimerCount()).toBeGreaterThanOrEqual(1)
      vi.useRealTimers()
    })

    it("does not set up timer when sessionTimeout is not provided", async () => {
      vi.useFakeTimers()
      const { login } = useAuth()
      await login("user@test.com", "pw")
      expect(vi.getTimerCount()).toBe(0)
      vi.useRealTimers()
    })

    it("does not call navigateTo on login", async () => {
      const { login } = useAuth({ redirectOnLogout: true })
      await login("user@test.com", "pw")
      expect(globalThis.navigateTo).not.toHaveBeenCalled()
    })
  })

  describe("logout", () => {
    it("calls logInfo with 'logout'", async () => {
      const { logout } = useAuth()
      await logout()
      expect(logInfo).toHaveBeenCalledWith("logout")
    })

    it("calls userStore.clearUser", async () => {
      const { logout } = useAuth()
      await logout()
      expect(mockClearUser).toHaveBeenCalledOnce()
    })

    it("calls navigateTo('/') when redirectOnLogout is true", async () => {
      const { logout } = useAuth({ redirectOnLogout: true })
      await logout()
      expect(globalThis.navigateTo).toHaveBeenCalledWith("/")
    })

    it("does not call navigateTo when redirectOnLogout is false", async () => {
      const { logout } = useAuth({ redirectOnLogout: false })
      await logout()
      expect(globalThis.navigateTo).not.toHaveBeenCalled()
    })

    it("does not call navigateTo when options are default (empty)", async () => {
      const { logout } = useAuth()
      await logout()
      expect(globalThis.navigateTo).not.toHaveBeenCalled()
    })
  })

  describe("useAuth options", () => {
    it("returns isLoggedIn, login and logout", () => {
      const result = useAuth()
      expect(result).toHaveProperty("isLoggedIn")
      expect(result).toHaveProperty("login")
      expect(result).toHaveProperty("logout")
    })

    it("accepts empty options object", () => {
      expect(() => useAuth({})).not.toThrow()
    })

    it("accepts all options", () => {
      expect(() => useAuth({ redirectOnLogout: true, sessionTimeout: 5000 })).not.toThrow()
    })
  })
})