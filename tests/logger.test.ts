import { describe, it, expect, vi, beforeEach, afterEach } from "vitest"
import { logInfo, logError, logWarn } from "../base-layer/utils/logger"

describe("logger", () => {
  let consoleLogSpy: ReturnType<typeof vi.spyOn>
  let consoleErrorSpy: ReturnType<typeof vi.spyOn>
  let consoleWarnSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    consoleLogSpy = vi.spyOn(console, "log").mockImplementation(() => {})
    consoleErrorSpy = vi.spyOn(console, "error").mockImplementation(() => {})
    consoleWarnSpy = vi.spyOn(console, "warn").mockImplementation(() => {})
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  describe("logInfo", () => {
    it("logs message with [INFO] prefix and timestamp", () => {
      logInfo("test message")
      expect(consoleLogSpy).toHaveBeenCalledOnce()
      const output = consoleLogSpy.mock.calls[0][0] as string
      expect(output).toMatch(/^\[INFO\] \d{4}-\d{2}-\d{2}T/)
      expect(output).toContain("test message")
    })

    it("includes context as JSON when provided", () => {
      logInfo("with context", { userId: 42, action: "login" })
      const output = consoleLogSpy.mock.calls[0][0] as string
      expect(output).toContain('{"userId":42,"action":"login"}')
    })

    it("omits context portion when context is undefined", () => {
      logInfo("no context")
      const output = consoleLogSpy.mock.calls[0][0] as string
      expect(output).not.toContain("{")
      expect(output).toMatch(/^\[INFO\] .+ no context$/)
    })

    it("includes a valid ISO timestamp", () => {
      const before = Date.now()
      logInfo("ts check")
      const after = Date.now()
      const output = consoleLogSpy.mock.calls[0][0] as string
      const match = output.match(/\[INFO\] (\S+) /)
      expect(match).not.toBeNull()
      const ts = new Date(match![1]).getTime()
      expect(ts).toBeGreaterThanOrEqual(before)
      expect(ts).toBeLessThanOrEqual(after)
    })

    it("handles empty context object", () => {
      logInfo("empty ctx", {})
      const output = consoleLogSpy.mock.calls[0][0] as string
      expect(output).toContain("{}")
    })

    it("handles context with nested objects", () => {
      logInfo("nested", { user: { id: 1, roles: ["admin"] } })
      const output = consoleLogSpy.mock.calls[0][0] as string
      expect(output).toContain('"user"')
      expect(output).toContain('"admin"')
    })

    it("does not call console.error or console.warn", () => {
      logInfo("only log")
      expect(consoleErrorSpy).not.toHaveBeenCalled()
      expect(consoleWarnSpy).not.toHaveBeenCalled()
    })
  })

  describe("logError", () => {
    it("logs message with [ERROR] prefix and timestamp", () => {
      logError("something failed")
      expect(consoleErrorSpy).toHaveBeenCalledOnce()
      const [output] = consoleErrorSpy.mock.calls[0] as [string, string]
      expect(output).toMatch(/^\[ERROR\] \d{4}-\d{2}-\d{2}T/)
      expect(output).toContain("something failed")
    })

    it("includes error stack when error is provided", () => {
      const err = new Error("boom")
      logError("with error", err)
      const args = consoleErrorSpy.mock.calls[0] as [string, string]
      expect(args[1]).toContain("boom")
    })

    it("uses empty string when no error is provided", () => {
      logError("no error arg")
      const args = consoleErrorSpy.mock.calls[0] as [string, string]
      expect(args[1]).toBe("")
    })

    it("uses empty string when error has no stack", () => {
      const err = new Error("no stack")
      delete err.stack
      logError("stackless", err)
      const args = consoleErrorSpy.mock.calls[0] as [string, string]
      expect(args[1]).toBe("")
    })

    it("does not call console.log or console.warn", () => {
      logError("only error")
      expect(consoleLogSpy).not.toHaveBeenCalled()
      expect(consoleWarnSpy).not.toHaveBeenCalled()
    })
  })

  describe("logWarn", () => {
    it("logs message with [WARN] prefix and timestamp", () => {
      logWarn("watch out")
      expect(consoleWarnSpy).toHaveBeenCalledOnce()
      const output = consoleWarnSpy.mock.calls[0][0] as string
      expect(output).toMatch(/^\[WARN\] \d{4}-\d{2}-\d{2}T/)
      expect(output).toContain("watch out")
    })

    it("includes a valid ISO timestamp", () => {
      const before = Date.now()
      logWarn("ts check")
      const after = Date.now()
      const output = consoleWarnSpy.mock.calls[0][0] as string
      const match = output.match(/\[WARN\] (\S+) /)
      expect(match).not.toBeNull()
      const ts = new Date(match![1]).getTime()
      expect(ts).toBeGreaterThanOrEqual(before)
      expect(ts).toBeLessThanOrEqual(after)
    })

    it("does not call console.log or console.error", () => {
      logWarn("only warn")
      expect(consoleLogSpy).not.toHaveBeenCalled()
      expect(consoleErrorSpy).not.toHaveBeenCalled()
    })

    it("handles empty string message", () => {
      logWarn("")
      expect(consoleWarnSpy).toHaveBeenCalledOnce()
      const output = consoleWarnSpy.mock.calls[0][0] as string
      expect(output).toMatch(/^\[WARN\] \S+ $/)
    })
  })
})