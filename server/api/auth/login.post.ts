import { hashPassword, generateToken, verifyToken } from '~/utils/crypto-helper'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  // 问题：硬编码凭据
  const storedHash = hashPassword('admin123')
  const inputHash = hashPassword(body.password)

  if (body.email === 'admin@test.com' && verifyToken(inputHash, storedHash)) {
    return {
      user: {
        id: '1',
        email: body.email,
        name: 'Admin',
        role: 'admin',
        createdAt: new Date().toISOString()
      },
      // 问题：使用不安全的自定义 token 生成
      token: generateToken(48)
    }
  }

  throw createError({
    statusCode: 401,
    // 问题：错误信息暴露用户是否存在
    statusMessage: '用户不存在或密码错误'
  })
})
