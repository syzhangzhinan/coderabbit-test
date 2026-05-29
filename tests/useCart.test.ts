import { describe, it, expect, vi, beforeEach } from "vitest"
import { ref, computed } from "vue"

// Nuxt auto-imports are globals in the Nuxt runtime but not in test environments.
// Stub them before importing the composable under test.
vi.stubGlobal("useState", (key: string, init: () => unknown) => ref(init()))
vi.stubGlobal("computed", computed)

import { useCart } from "../composables/useCart"
import type { CartItem } from "../composables/useCart"

describe("useCart", () => {
  // Each test gets a fresh useCart instance via a fresh call
  let cart: ReturnType<typeof useCart>

  beforeEach(() => {
    cart = useCart()
    // Clear items between tests
    cart.items.value = []
  })

  describe("initial state", () => {
    it("starts with an empty items list", () => {
      expect(cart.items.value).toEqual([])
    })

    it("starts with a total of 0", () => {
      expect(cart.total.value).toBe(0)
    })
  })

  describe("addItem", () => {
    it("adds a new item with quantity 1", () => {
      cart.addItem({ id: "p1", name: "Apple", price: 10 })
      expect(cart.items.value).toHaveLength(1)
      expect(cart.items.value[0]).toEqual({ id: "p1", name: "Apple", price: 10, quantity: 1 })
    })

    it("increments quantity when same id is added again", () => {
      cart.addItem({ id: "p1", name: "Apple", price: 10 })
      cart.addItem({ id: "p1", name: "Apple", price: 10 })
      expect(cart.items.value).toHaveLength(1)
      expect(cart.items.value[0].quantity).toBe(2)
    })

    it("adds a second distinct item as a separate entry", () => {
      cart.addItem({ id: "p1", name: "Apple", price: 10 })
      cart.addItem({ id: "p2", name: "Banana", price: 5 })
      expect(cart.items.value).toHaveLength(2)
    })

    it("preserves name and price when incrementing quantity", () => {
      cart.addItem({ id: "p1", name: "Apple", price: 10 })
      cart.addItem({ id: "p1", name: "Apple", price: 10 })
      expect(cart.items.value[0].name).toBe("Apple")
      expect(cart.items.value[0].price).toBe(10)
    })

    it("handles items with zero price", () => {
      cart.addItem({ id: "free", name: "Free Item", price: 0 })
      expect(cart.items.value[0].price).toBe(0)
      expect(cart.total.value).toBe(0)
    })
  })

  describe("removeItem", () => {
    it("removes the item with the matching id", () => {
      cart.addItem({ id: "p1", name: "Apple", price: 10 })
      cart.addItem({ id: "p2", name: "Banana", price: 5 })
      cart.removeItem("p1")
      expect(cart.items.value).toHaveLength(1)
      expect(cart.items.value[0].id).toBe("p2")
    })

    it("is a no-op when id does not exist", () => {
      cart.addItem({ id: "p1", name: "Apple", price: 10 })
      cart.removeItem("nonexistent")
      expect(cart.items.value).toHaveLength(1)
    })

    it("results in empty list when the only item is removed", () => {
      cart.addItem({ id: "p1", name: "Apple", price: 10 })
      cart.removeItem("p1")
      expect(cart.items.value).toEqual([])
    })

    it("does not affect other items with different ids", () => {
      cart.addItem({ id: "a", name: "A", price: 1 })
      cart.addItem({ id: "b", name: "B", price: 2 })
      cart.addItem({ id: "c", name: "C", price: 3 })
      cart.removeItem("b")
      expect(cart.items.value.map((i) => i.id)).toEqual(["a", "c"])
    })
  })

  describe("total (computed)", () => {
    it("sums price * quantity for all items", () => {
      cart.items.value = [
        { id: "p1", name: "A", price: 10, quantity: 2 },
        { id: "p2", name: "B", price: 5, quantity: 3 },
      ] as CartItem[]
      expect(cart.total.value).toBe(10 * 2 + 5 * 3)
    })

    it("returns 0 for an empty cart", () => {
      expect(cart.total.value).toBe(0)
    })

    it("updates reactively after addItem", () => {
      cart.addItem({ id: "p1", name: "A", price: 7 })
      expect(cart.total.value).toBe(7)
      cart.addItem({ id: "p1", name: "A", price: 7 })
      expect(cart.total.value).toBe(14)
    })

    it("updates reactively after removeItem", () => {
      cart.addItem({ id: "p1", name: "A", price: 10 })
      cart.addItem({ id: "p2", name: "B", price: 5 })
      cart.removeItem("p1")
      expect(cart.total.value).toBe(5)
    })

    it("handles floating point prices", () => {
      cart.addItem({ id: "p1", name: "Float", price: 1.5 })
      cart.addItem({ id: "p2", name: "Float2", price: 2.5 })
      expect(cart.total.value).toBeCloseTo(4.0)
    })
  })
})