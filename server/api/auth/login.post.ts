import { createHmac, randomUUID } from 'crypto'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)

  if (!body.email || !body.password) {
    throw createError({ statusCode: 400, statusMessage: '请提供邮箱和密码' })
  }

  // In production: use bcrypt + database lookup
  const storedHash = createHmac('sha256', 'server-secret').update('admin123').digest('hex')
  const inputHash = createHmac('sha256', 'server-secret').update(body.password).digest('hex')

  if (body.email === 'admin@test.com' && storedHash === inputHash) {
    return {
      user: {
        id: '1',
        email: body.email,
        name: 'Admin',
        role: 'admin',
        createdAt: new Date().toISOString()
      },
      token: randomUUID()
    }
  }

  throw createError({ statusCode: 401, statusMessage: '认证失败' })
})
