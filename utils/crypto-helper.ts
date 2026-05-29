/**
 * 加密工具
 *
 * Web Search 测试场景 3: 使用 Node.js crypto API — 验证算法参数是否正确
 * Web Search 测试场景 4: 使用已废弃的 API — 触发 web search 检测废弃状态
 */

import { createHash, createCipheriv, randomBytes, scryptSync } from "crypto"

// 场景 3: 使用 crypto API — AI 应通过 web search 验证加密参数
// 修改点: 将 sha256 改为 sha512，或修改 IV 长度参数
export function hashPassword(password: string, salt: string): string {
  return createHash("sha256")
    .update(password + salt)
    .digest("hex")
}

// 场景 3: AES 加密 — AI 应验证 key/iv 长度是否匹配算法要求
export function encryptData(data: string, password: string): string {
  const salt = randomBytes(16)
  const key = scryptSync(password, salt, 32) // 256-bit key for aes-256-cbc
  const iv = randomBytes(16) // AES block size = 16 bytes
  const cipher = createCipheriv("aes-256-cbc", key, iv)
  // const cipher = createCipheriv("aes-128-cbc", key, iv)
  let encrypted = cipher.update(data, "utf8", "hex")
  encrypted += cipher.final("hex")
  return `${salt.toString("hex")}:${iv.toString("hex")}:${encrypted}`
}

// 场景 4: 使用废弃的 API — createCipher 在 Node.js 中已废弃
// 修改点: 从 createCipheriv 改为 createCipher（已废弃）
// @ts-ignore — 测试用，故意使用废弃 API
export function legacyEncrypt(data: string, password: string): string {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const { createCipher } = require("crypto")
  const cipher = createCipher("aes-256-cbc", password)
  let encrypted = cipher.update(data, "utf8", "hex")
  encrypted += cipher.final("hex")
  return encrypted
}

// 新增使用废弃 API 的函数
// + export function quickHash(data: string): string {
//    const { createCipher } = require("crypto")
//    const cipher = createCipher("aes-256-cbc", "weak-password")
//    return cipher.update(data, "utf8", "hex") + cipher.final("hex")
//  }
