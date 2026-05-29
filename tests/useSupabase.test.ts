import { describe, it, expect, vi, beforeEach } from "vitest"

// vi.hoisted runs before vi.mock factories, ensuring variables are initialized
// before the mock factory references them.
const {
  mockOrder,
  mockEq,
  mockSelect,
  mockFrom,
  mockSignInWithPassword,
  mockSubscribe,
  mockOn,
  mockChannel,
} = vi.hoisted(() => ({
  mockOrder: vi.fn().mockResolvedValue({ data: [], error: null }),
  mockEq: vi.fn(),
  mockSelect: vi.fn(),
  mockFrom: vi.fn(),
  mockSignInWithPassword: vi.fn(),
  mockSubscribe: vi.fn().mockReturnValue({ unsubscribe: vi.fn() }),
  mockOn: vi.fn(),
  mockChannel: vi.fn(),
}))

vi.mock("@supabase/supabase-js", () => {
  // Wire up the query builder chain
  mockEq.mockReturnValue({ order: mockOrder })
  mockSelect.mockReturnValue({ eq: mockEq, order: mockOrder })
  mockFrom.mockReturnValue({ select: mockSelect })
  mockOn.mockReturnValue({ subscribe: mockSubscribe })
  mockChannel.mockReturnValue({ on: mockOn })

  return {
    createClient: vi.fn(() => ({
      from: mockFrom,
      auth: { signInWithPassword: mockSignInWithPassword },
      channel: mockChannel,
    })),
  }
})

import { getProducts, loginUser, subscribeToProducts } from "../composables/useSupabase"

describe("useSupabase", () => {
  beforeEach(() => {
    mockOrder.mockClear()
    mockEq.mockClear()
    mockSelect.mockClear()
    mockFrom.mockClear()
    mockSignInWithPassword.mockClear()
    mockSubscribe.mockClear()
    mockOn.mockClear()
    mockChannel.mockClear()

    // Re-wire chain after clearing mock state
    mockOrder.mockResolvedValue({ data: [], error: null })
    mockEq.mockReturnValue({ order: mockOrder })
    mockSelect.mockReturnValue({ eq: mockEq, order: mockOrder })
    mockFrom.mockReturnValue({ select: mockSelect })
    mockSubscribe.mockReturnValue({ unsubscribe: vi.fn() })
    mockOn.mockReturnValue({ subscribe: mockSubscribe })
    mockChannel.mockReturnValue({ on: mockOn })
  })

  describe("getProducts", () => {
    it("queries the products table with expected columns", async () => {
      mockOrder.mockResolvedValue({ data: [], error: null })
      await getProducts()
      expect(mockFrom).toHaveBeenCalledWith("products")
      expect(mockSelect).toHaveBeenCalledWith("id, name, price, category")
    })

    it("orders results by created_at descending", async () => {
      mockOrder.mockResolvedValue({ data: [], error: null })
      await getProducts()
      expect(mockOrder).toHaveBeenCalledWith("created_at", { ascending: false })
    })

    it("returns the data array on success", async () => {
      const fakeProducts = [{ id: "1", name: "Widget", price: 9.99, category: "tools" }]
      mockOrder.mockResolvedValue({ data: fakeProducts, error: null })
      const result = await getProducts()
      expect(result).toEqual(fakeProducts)
    })

    it("applies eq filter when category is provided", async () => {
      mockOrder.mockResolvedValue({ data: [], error: null })
      await getProducts("electronics")
      expect(mockEq).toHaveBeenCalledWith("category", "electronics")
    })

    it("does not apply eq filter when category is undefined", async () => {
      mockOrder.mockResolvedValue({ data: [], error: null })
      await getProducts()
      // eq should not be called when no category is given
      expect(mockEq).not.toHaveBeenCalled()
    })

    it("does not apply eq filter when category is empty string", async () => {
      mockOrder.mockResolvedValue({ data: [], error: null })
      await getProducts("")
      expect(mockEq).not.toHaveBeenCalled()
    })

    it("throws when the query returns an error", async () => {
      const dbError = new Error("Database connection failed")
      mockOrder.mockResolvedValue({ data: null, error: dbError })
      await expect(getProducts()).rejects.toThrow("Database connection failed")
    })

    it("throws when category query returns an error", async () => {
      const dbError = new Error("Permission denied")
      mockOrder.mockResolvedValue({ data: null, error: dbError })
      await expect(getProducts("electronics")).rejects.toThrow("Permission denied")
    })
  })

  describe("loginUser", () => {
    it("calls signInWithPassword with email and password", async () => {
      const mockSession = { access_token: "token123", user: { id: "u1" } }
      mockSignInWithPassword.mockResolvedValue({ data: { session: mockSession }, error: null })
      await loginUser("alice@example.com", "secret")
      expect(mockSignInWithPassword).toHaveBeenCalledWith({
        email: "alice@example.com",
        password: "secret",
      })
    })

    it("returns the session on successful login", async () => {
      const mockSession = { access_token: "abc", user: { id: "user-1" } }
      mockSignInWithPassword.mockResolvedValue({ data: { session: mockSession }, error: null })
      const session = await loginUser("alice@example.com", "secret")
      expect(session).toEqual(mockSession)
    })

    it("throws when authentication fails", async () => {
      const authError = new Error("Invalid credentials")
      mockSignInWithPassword.mockResolvedValue({ data: { session: null }, error: authError })
      await expect(loginUser("bad@user.com", "wrong")).rejects.toThrow("Invalid credentials")
    })

    it("throws when network error occurs", async () => {
      mockSignInWithPassword.mockRejectedValue(new Error("Network error"))
      await expect(loginUser("user@example.com", "pw")).rejects.toThrow("Network error")
    })

    it("returns null session when session is null (no error)", async () => {
      mockSignInWithPassword.mockResolvedValue({ data: { session: null }, error: null })
      const session = await loginUser("user@example.com", "pw")
      expect(session).toBeNull()
    })
  })

  describe("subscribeToProducts", () => {
    it("creates a channel named products-changes", () => {
      subscribeToProducts(vi.fn())
      expect(mockChannel).toHaveBeenCalledWith("products-changes")
    })

    it("subscribes to postgres_changes events on public.products", () => {
      subscribeToProducts(vi.fn())
      expect(mockOn).toHaveBeenCalledWith(
        "postgres_changes",
        { event: "*", schema: "public", table: "products" },
        expect.any(Function)
      )
    })

    it("calls subscribe() to activate the channel", () => {
      subscribeToProducts(vi.fn())
      expect(mockSubscribe).toHaveBeenCalledOnce()
    })

    it("passes the callback to the on() handler", () => {
      const callback = vi.fn()
      subscribeToProducts(callback)
      const [, , passedCallback] = mockOn.mock.calls[0] as [string, unknown, (payload: unknown) => void]
      expect(passedCallback).toBe(callback)
    })

    it("returns the subscription object from subscribe()", () => {
      const fakeSubscription = { unsubscribe: vi.fn(), state: "subscribed" }
      mockSubscribe.mockReturnValue(fakeSubscription)
      const result = subscribeToProducts(vi.fn())
      expect(result).toBe(fakeSubscription)
    })
  })
})