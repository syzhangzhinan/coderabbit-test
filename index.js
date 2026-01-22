/**
 * Web 端常用工具库（零依赖）
 * - 支持 ESM/打包器：具名导出 + default 导出
 * - 浏览器环境：可选挂载到 window.WebUtils（不覆盖已有同名）
 *
 * 说明：该文件刻意避免引入第三方依赖，适合直接拷贝到项目中使用。
 */

/* ==============================
 * 基础类型判断
 * ============================== */

const toString = Object.prototype.toString;
const hasOwn = Object.prototype.hasOwnProperty;

export const isUndefined = (v) => v === undefined;
export const isNull = (v) => v === null;
export const isNil = (v) => v == null; // null 或 undefined
export const isString = (v) => typeof v === "string";
export const isNumber = (v) => typeof v === "number" && !Number.isNaN(v);
export const isBoolean = (v) => typeof v === "boolean";
export const isFunction = (v) => typeof v === "function";
export const isArray = Array.isArray;
export const isDate = (v) => toString.call(v) === "[object Date]" && !Number.isNaN(v?.getTime?.());
export const isRegExp = (v) => toString.call(v) === "[object RegExp]";
export const isObject = (v) => v !== null && typeof v === "object";
export const isPlainObject = (v) => {
  if (!isObject(v) || toString.call(v) !== "[object Object]") return false;
  const proto = Object.getPrototypeOf(v);
  return proto === null || proto === Object.prototype;
};

export const isEmpty = (v) => {
  if (isNil(v)) return true;
  if (isString(v)) return v.trim().length === 0;
  if (isArray(v)) return v.length === 0;
  if (v instanceof Map || v instanceof Set) return v.size === 0;
  if (isPlainObject(v)) return Object.keys(v).length === 0;
  return false;
};

/* ==============================
 * 数值/随机
 * ============================== */

export const clamp = (n, min, max) => Math.min(max, Math.max(min, n));
export const randomInt = (min, max) => {
  const a = Math.ceil(min);
  const b = Math.floor(max);
  return Math.floor(Math.random() * (b - a + 1)) + a;
};

/* ==============================
 * Promise/时间
 * ============================== */

export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

export const pad2 = (n) => String(n).padStart(2, "0");
export const formatDate = (date = new Date(), pattern = "YYYY-MM-DD HH:mm:ss") => {
  const d = date instanceof Date ? date : new Date(date);
  if (Number.isNaN(d.getTime())) return "";
  const YYYY = String(d.getFullYear());
  const MM = pad2(d.getMonth() + 1);
  const DD = pad2(d.getDate());
  const HH = pad2(d.getHours());
  const mm = pad2(d.getMinutes());
  const ss = pad2(d.getSeconds());
  return pattern
    .replaceAll("YYYY", YYYY)
    .replaceAll("MM", MM)
    .replaceAll("DD", DD)
    .replaceAll("HH", HH)
    .replaceAll("mm", mm)
    .replaceAll("ss", ss);
};

/* ==============================
 * 函数控制：防抖/节流/只执行一次
 * ============================== */

/**
 * 防抖：在最后一次触发 delay 后执行
 * @param {Function} fn
 * @param {number} delay
 * @param {{leading?: boolean, trailing?: boolean}} [options]
 */
export const debounce = (fn, delay = 200, options = {}) => {
  const { leading = false, trailing = true } = options;
  let timer = null;
  let lastArgs;
  let lastThis;
  let leadingCalled = false;

  const invoke = () => {
    timer = null;
    if (trailing && lastArgs) {
      fn.apply(lastThis, lastArgs);
      lastArgs = lastThis = null;
    }
    leadingCalled = false;
  };

  const debounced = function (...args) {
    lastArgs = args;
    lastThis = this;

    if (!timer && leading && !leadingCalled) {
      leadingCalled = true;
      fn.apply(lastThis, lastArgs);
      lastArgs = lastThis = null;
    }

    if (timer) clearTimeout(timer);
    timer = setTimeout(invoke, delay);
  };

  debounced.cancel = () => {
    if (timer) clearTimeout(timer);
    timer = null;
    lastArgs = lastThis = null;
    leadingCalled = false;
  };

  return debounced;
};

/**
 * 节流：在 interval 内最多执行一次
 * @param {Function} fn
 * @param {number} interval
 * @param {{leading?: boolean, trailing?: boolean}} [options]
 */
export const throttle = (fn, interval = 200, options = {}) => {
  const { leading = true, trailing = true } = options;
  let lastTime = 0;
  let timer = null;
  let lastArgs;
  let lastThis;

  const invoke = (time) => {
    lastTime = time;
    timer = null;
    fn.apply(lastThis, lastArgs);
    lastArgs = lastThis = null;
  };

  const throttled = function (...args) {
    const now = Date.now();
    if (!lastTime && !leading) lastTime = now;

    const remaining = interval - (now - lastTime);
    lastArgs = args;
    lastThis = this;

    if (remaining <= 0 || remaining > interval) {
      if (timer) {
        clearTimeout(timer);
        timer = null;
      }
      invoke(now);
    } else if (!timer && trailing) {
      timer = setTimeout(() => invoke(Date.now()), remaining);
    }
  };

  throttled.cancel = () => {
    if (timer) clearTimeout(timer);
    timer = null;
    lastTime = 0;
    lastArgs = lastThis = null;
  };

  return throttled;
};

export const once = (fn) => {
  let called = false;
  let result;
  return function (...args) {
    if (called) return result;
    called = true;
    result = fn.apply(this, args);
    return result;
  };
};

/* ==============================
 * JSON / 安全解析
 * ============================== */

export const safeJSONParse = (text, fallback = null) => {
  if (!isString(text)) return fallback;
  try {
    return JSON.parse(text);
  } catch {
    return fallback;
  }
};

export const safeJSONStringify = (value, fallback = "") => {
  try {
    return JSON.stringify(value);
  } catch {
    return fallback;
  }
};

/* ==============================
 * 深拷贝 / 深合并
 * ============================== */

export const deepClone = (input) => {
  // 首选原生 structuredClone（现代浏览器/Node 17+）
  if (typeof globalThis?.structuredClone === "function") {
    try {
      return globalThis.structuredClone(input);
    } catch {
      // 继续 fallback
    }
  }

  const seen = new Map();

  const cloneAny = (v) => {
    if (!isObject(v)) return v;
    if (seen.has(v)) return seen.get(v);

    if (isDate(v)) return new Date(v.getTime());
    if (isRegExp(v)) return new RegExp(v.source, v.flags);
    if (v instanceof Map) {
      const m = new Map();
      seen.set(v, m);
      v.forEach((val, key) => m.set(cloneAny(key), cloneAny(val)));
      return m;
    }
    if (v instanceof Set) {
      const s = new Set();
      seen.set(v, s);
      v.forEach((val) => s.add(cloneAny(val)));
      return s;
    }
    if (isArray(v)) {
      const arr = [];
      seen.set(v, arr);
      for (const item of v) arr.push(cloneAny(item));
      return arr;
    }
    if (v instanceof ArrayBuffer) return v.slice(0);
    if (ArrayBuffer.isView?.(v)) return new v.constructor(v);

    // 只处理普通对象（保留原型会带来边界复杂度，这里走安全策略：仅 plain object）
    if (isPlainObject(v)) {
      const obj = {};
      seen.set(v, obj);
      for (const k of Object.keys(v)) obj[k] = cloneAny(v[k]);
      return obj;
    }
    return v; // 其它对象类型（如 DOM 节点）不深拷贝
  };

  return cloneAny(input);
};

export const deepMerge = (target, ...sources) => {
  const out = isPlainObject(target) ? deepClone(target) : {};
  for (const src of sources) {
    if (!isPlainObject(src)) continue;
    for (const key of Object.keys(src)) {
      const tv = out[key];
      const sv = src[key];
      if (isPlainObject(tv) && isPlainObject(sv)) out[key] = deepMerge(tv, sv);
      else out[key] = deepClone(sv);
    }
  }
  return out;
};

/* ==============================
 * URL / QueryString
 * ============================== */

export const parseQueryString = (input = "") => {
  const q = input.startsWith("?") ? input.slice(1) : input;
  const params = new URLSearchParams(q);
  const obj = {};
  for (const [k, v] of params.entries()) {
    if (hasOwn.call(obj, k)) {
      const cur = obj[k];
      obj[k] = isArray(cur) ? [...cur, v] : [cur, v];
    } else {
      obj[k] = v;
    }
  }
  return obj;
};

export const buildQueryString = (obj = {}) => {
  const params = new URLSearchParams();
  if (!isObject(obj)) return "";
  for (const [k, v] of Object.entries(obj)) {
    if (isNil(v)) continue;
    if (isArray(v)) v.forEach((item) => params.append(k, String(item)));
    else params.set(k, String(v));
  }
  const s = params.toString();
  return s ? `?${s}` : "";
};

export const getQueryParam = (key, url = globalThis?.location?.href) => {
  if (!url) return null;
  try {
    const u = new URL(url, globalThis?.location?.origin);
    return u.searchParams.get(key);
  } catch {
    return null;
  }
};

export const setQueryParam = (key, value, url = globalThis?.location?.href) => {
  if (!url) return "";
  try {
    const u = new URL(url, globalThis?.location?.origin);
    if (isNil(value)) u.searchParams.delete(key);
    else u.searchParams.set(key, String(value));
    return u.toString();
  } catch {
    return url;
  }
};

/* ==============================
 * 存储：localStorage / sessionStorage（带 JSON）
 * ============================== */

const createStorage = (storage) => {
  const canUse = () => {
    try {
      const k = "__web_utils_test__";
      storage.setItem(k, "1");
      storage.removeItem(k);
      return true;
    } catch {
      return false;
    }
  };

  return {
    available: () => Boolean(storage) && canUse(),
    get: (key, fallback = null) => {
      try {
        const v = storage.getItem(key);
        return v === null ? fallback : v;
      } catch {
        return fallback;
      }
    },
    set: (key, value) => {
      try {
        storage.setItem(key, String(value));
        return true;
      } catch {
        return false;
      }
    },
    remove: (key) => {
      try {
        storage.removeItem(key);
        return true;
      } catch {
        return false;
      }
    },
    clear: () => {
      try {
        storage.clear();
        return true;
      } catch {
        return false;
      }
    },
    getJSON: (key, fallback = null) => safeJSONParse(storage?.getItem?.(key) ?? null, fallback),
    setJSON: (key, value) => {
      try {
        storage.setItem(key, safeJSONStringify(value));
        return true;
      } catch {
        return false;
      }
    },
  };
};

export const local = createStorage(globalThis?.localStorage);
export const session = createStorage(globalThis?.sessionStorage);

/* ==============================
 * Cookie
 * ============================== */

export const getCookie = (name) => {
  if (!globalThis?.document?.cookie) return "";
  const cookies = globalThis.document.cookie.split("; ");
  for (const item of cookies) {
    const idx = item.indexOf("=");
    const k = decodeURIComponent(idx >= 0 ? item.slice(0, idx) : item);
    if (k === name) return decodeURIComponent(idx >= 0 ? item.slice(idx + 1) : "");
  }
  return "";
};

export const setCookie = (name, value, options = {}) => {
  if (!globalThis?.document) return false;
  const { days, path = "/", domain, secure, sameSite = "Lax" } = options;
  let cookie = `${encodeURIComponent(name)}=${encodeURIComponent(String(value))}`;
  if (isNumber(days)) {
    const d = new Date();
    d.setTime(d.getTime() + days * 864e5);
    cookie += `; Expires=${d.toUTCString()}`;
  }
  if (path) cookie += `; Path=${path}`;
  if (domain) cookie += `; Domain=${domain}`;
  if (secure) cookie += "; Secure";
  if (sameSite) cookie += `; SameSite=${sameSite}`;
  globalThis.document.cookie = cookie;
  return true;
};

export const removeCookie = (name, options = {}) => setCookie(name, "", { ...options, days: -1 });

/* ==============================
 * DOM：选择器/事件/就绪/复制
 * ============================== */

export const qs = (selector, root = globalThis?.document) => root?.querySelector?.(selector) ?? null;
export const qsa = (selector, root = globalThis?.document) => Array.from(root?.querySelectorAll?.(selector) ?? []);

export const on = (el, event, handler, options) => {
  el?.addEventListener?.(event, handler, options);
  return () => off(el, event, handler, options);
};
export const off = (el, event, handler, options) => el?.removeEventListener?.(event, handler, options);

export const ready = (cb) => {
  const d = globalThis?.document;
  if (!d) return;
  if (d.readyState === "complete" || d.readyState === "interactive") cb();
  else d.addEventListener("DOMContentLoaded", cb, { once: true });
};

export const copyToClipboard = async (text) => {
  const t = String(text ?? "");
  // 优先使用异步 Clipboard API
  if (globalThis?.navigator?.clipboard?.writeText) {
    await globalThis.navigator.clipboard.writeText(t);
    return true;
  }
  // fallback：execCommand
  const d = globalThis?.document;
  if (!d) return false;
  const textarea = d.createElement("textarea");
  textarea.value = t;
  textarea.setAttribute("readonly", "readonly");
  textarea.style.position = "fixed";
  textarea.style.top = "-9999px";
  d.body.appendChild(textarea);
  textarea.select();
  const ok = d.execCommand?.("copy") ?? false;
  d.body.removeChild(textarea);
  return ok;
};

export const getScrollTop = (el = globalThis?.document?.documentElement) => el?.scrollTop ?? 0;
export const scrollToTop = (behavior = "smooth") => globalThis?.scrollTo?.({ top: 0, behavior });

/* ==============================
 * 字符串：HTML 转义/Base64（支持 Unicode）
 * ============================== */

export const escapeHTML = (str) =>
  String(str ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");

export const unescapeHTML = (str) =>
  String(str ?? "")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">")
    .replaceAll("&quot;", '"')
    .replaceAll("&#39;", "'")
    .replaceAll("&amp;", "&");

export const base64Encode = (str) => {
  const s = String(str ?? "");
  if (typeof globalThis?.btoa === "function") {
    // 处理 Unicode：先转 UTF-8，再 btoa
    const utf8 = new TextEncoder().encode(s);
    let bin = "";
    utf8.forEach((b) => (bin += String.fromCharCode(b)));
    return globalThis.btoa(bin);
  }
  return "";
};

export const base64Decode = (b64) => {
  const s = String(b64 ?? "");
  if (typeof globalThis?.atob === "function") {
    const bin = globalThis.atob(s);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return new TextDecoder().decode(bytes);
  }
  return "";
};

/* ==============================
 * UUID
 * ============================== */

export const uuidv4 = () => {
  if (globalThis?.crypto?.randomUUID) return globalThis.crypto.randomUUID();
  const rnd = (n) => {
    const a = new Uint8Array(n);
    if (globalThis?.crypto?.getRandomValues) globalThis.crypto.getRandomValues(a);
    else for (let i = 0; i < n; i++) a[i] = Math.floor(Math.random() * 256);
    return a;
  };
  const b = rnd(16);
  // RFC 4122 v4
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  const hex = Array.from(b, (x) => x.toString(16).padStart(2, "0"));
  return `${hex.slice(0, 4).join("")}-${hex.slice(4, 6).join("")}-${hex.slice(6, 8).join("")}-${hex
    .slice(8, 10)
    .join("")}-${hex.slice(10, 16).join("")}`;
};

/* ==============================
 * 网络：fetch JSON（带超时/Abort）
 * ============================== */

export class HTTPError extends Error {
  constructor(message, { status, statusText, url, body } = {}) {
    super(message);
    this.name = "HTTPError";
    this.status = status;
    this.statusText = statusText;
    this.url = url;
    this.body = body;
  }
}

/**
 * fetchJSON：默认解析 JSON；非 2xx 抛 HTTPError
 * @param {string} url
 * @param {RequestInit & { timeoutMs?: number, parse?: "json"|"text"|"raw" }} [options]
 */
export const fetchJSON = async (url, options = {}) => {
  const { timeoutMs = 15000, parse = "json", ...init } = options;
  const controller = new AbortController();
  const signal = init.signal ? init.signal : controller.signal;

  const timer = setTimeout(() => controller.abort(new DOMException("Request timeout", "AbortError")), timeoutMs);
  try {
    const res = await fetch(url, { ...init, signal });
    const contentType = res.headers.get("content-type") || "";

    let body;
    if (parse === "raw") body = res;
    else if (parse === "text") body = await res.text();
    else if (contentType.includes("application/json")) body = await res.json();
    else body = safeJSONParse(await res.text(), null);

    if (!res.ok) {
      throw new HTTPError(`HTTP ${res.status} ${res.statusText}`, {
        status: res.status,
        statusText: res.statusText,
        url: res.url || url,
        body,
      });
    }
    return body;
  } finally {
    clearTimeout(timer);
  }
};

/* ==============================
 * 统一导出
 * ============================== */

export const WebUtils = {
  // type
  isUndefined,
  isNull,
  isNil,
  isString,
  isNumber,
  isBoolean,
  isFunction,
  isArray,
  isDate,
  isRegExp,
  isObject,
  isPlainObject,
  isEmpty,

  // number/time
  clamp,
  randomInt,
  sleep,
  pad2,
  formatDate,

  // fn
  debounce,
  throttle,
  once,

  // json
  safeJSONParse,
  safeJSONStringify,

  // clone/merge
  deepClone,
  deepMerge,

  // url
  parseQueryString,
  buildQueryString,
  getQueryParam,
  setQueryParam,

  // storage/cookie
  local,
  session,
  getCookie,
  setCookie,
  removeCookie,

  // dom
  qs,
  qsa,
  on,
  off,
  ready,
  copyToClipboard,
  getScrollTop,
  scrollToTop,

  // string
  escapeHTML,
  unescapeHTML,
  base64Encode,
  base64Decode,

  // uuid/network
  uuidv4,
  HTTPError,
  fetchJSON,
};

export default WebUtils;

// 可选挂载到 window（避免覆盖）
if (typeof window !== "undefined") {
  window.WebUtils = window.WebUtils || WebUtils;
}

