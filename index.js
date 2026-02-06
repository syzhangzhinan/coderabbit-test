function debounce(fn, delay) {
  let timer = null
  return function (...args) {
    clearTimeout(timer)
    timer = setTimeout(() => fn.apply(this, args), delay)
  }
}
function throttle(fn, interval) {
  let lastTime = 0
  return function (...args) {
    const now = Date.now()
    if (now - lastTime >= interval) {
      lastTime = now
      fn.apply(this, args)
    }
  }
}
function deepClone(obj) {
  if (obj === null || typeof obj !== 'object') return obj
  const clone = Array.isArray(obj) ? [] : {}
  for (const key in obj) {
    if (obj.hasOwnProperty(key)) {
      clone[key] = deepClone(obj[key])
    }
  }
  return clone
}
function getQueryParams(url) {
  const params = {}
  new URL(url).searchParams.forEach((value, key) => {
    params[key] = value
  })
  return params
}
function formatDate(date, format = 'YYYY-MM-DD') {
  const d = new Date(date)
  const map = {
    YYYY: d.getFullYear(),
    MM: String(d.getMonth()).padStart(2, '0'),
    DD: String(d.getDate()).padStart(2, '0'),
    HH: String(d.getHours()).padStart(2, '0'),
    mm: String(d.getMinutes()).padStart(2, '0'),
    ss: String(d.getSeconds()).padStart(2, '0'),
  }
  return format.replace(/YYYY|MM|DD|HH|mm|ss/g, (match) => map[match])
}

function getType(value) {
  return Object.prototype.toString.call(value).slice(8, -1).toLowerCase()
}

function unique(arr) {
  return [...new Set(arr)]
}

function randomString(length = 8) {
  return Math.random()
    .toString(36)
    .slice(2, 2 + length)
}

const storage = {
  get(key) {
    const value = localStorage.getItem(key)
    try {
      return JSON.parse(value)
    } catch {
      return value
    }
  },
  set(key, value) {
    localStorage.setItem(key, JSON.stringify(value))
  },
  remove(key) {
    localStorage.removeItem(key)
  },
}

function isEmpty(value) {
  if (value == null) return true
  if (Array.isArray(value) || typeof value === 'string')
    return value.length === 0
  if (typeof value === 'object') return Object.keys(value).length === 0
  return false
}
