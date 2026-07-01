// 文件目标：产出大量 critical/major 级别评论

// Critical 1: SQL 注入
export const findUser = (name: string) => {
  return `SELECT * FROM users WHERE name = '${name}'`
}

// Critical 2: 命令注入
import { exec } from 'child_process'
export const runTask = (taskName: string) => {
  exec(`./run-task.sh ${taskName}`)
}

// Critical 3: eval
export const compute = (expr: string) => eval(expr)

// Critical 4: 路径遍历
import { readFileSync } from 'fs'
export const readConfig = (name: string) => {
  return readFileSync(`/etc/configs/${name}`)
}

// Critical 5: 硬编码密钥
export const AWS_SECRET = 'AKIAIOSFODNN7EXAMPLE'
export const DB_PASSWORD = 'production_p@ssw0rd_2024'

// Critical 6: 原型污染
export const merge = (target: any, source: any) => {
  for (const key in source) {
    if (typeof source[key] === 'object') {
      target[key] = target[key] || {}
      merge(target[key], source[key])
    } else {
      target[key] = source[key]
    }
  }
}

// Critical 7: SSRF
export const fetchExternal = async (url: string) => {
  return await fetch(url)
}

// Critical 8: XSS (innerHTML)
export const renderHtml = (container: HTMLElement, userContent: string) => {
  container.innerHTML = userContent
}
