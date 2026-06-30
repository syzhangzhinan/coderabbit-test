import { exec } from 'child_process'
import { promisify } from 'util'

const execAsync = promisify(exec)

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const template = body.template as string

  if (!template) {
    throw createError({ statusCode: 400, statusMessage: 'Missing template' })
  }

  // 问题 (命令注入)：用户输入拼接到 shell 命令
  const { stdout } = await execAsync(`echo "${template}" | pandoc -f markdown -t html`)

  return { html: stdout }
})
