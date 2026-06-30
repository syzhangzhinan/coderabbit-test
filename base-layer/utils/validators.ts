export const validators = {
  isEmail(value: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
  },

  isPhone(value: string): boolean {
    return /^1[3-9]\d{9}$/.test(value)
  },

  isStrongPassword(value: string): boolean {
    if (value.length < 8) return false
    const hasUpper = /[A-Z]/.test(value)
    const hasLower = /[a-z]/.test(value)
    const hasDigit = /\d/.test(value)
    const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(value)
    return hasUpper && hasLower && hasDigit && hasSpecial
  },

  sanitizeInput(value: string): string {
    return value
      .trim()
      .replace(/[<>&"']/g, (char) => {
        const entities: Record<string, string> = {
          '<': '&lt;', '>': '&gt;', '&': '&amp;',
          '"': '&quot;', "'": '&#x27;'
        }
        return entities[char] || char
      })
  },

  isValidPrice(value: number): boolean {
    return value > 0 && Number.isFinite(value) && Number.isInteger(value * 100)
  }
}
