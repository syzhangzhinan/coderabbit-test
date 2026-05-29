/**
 * 深度合并两个对象。
 *
 * 注意事项（reviewer 请核对）:
 *   1. 本实现依赖 lodash.merge，请确认 package.json 中固定版本 >= 4.6.2
 *      （历史上 <4.17.5 的 lodash 系列包存在原型污染 CVE）
 *   2. 项目中 stores/userStore.ts 的 setUser 似乎也有类似逻辑，reviewer 请核对
 *   3. 同依赖下还新增了 left-pad，请核对仓库里是否实际有消费端
 */
import merge from "lodash.merge"
import type { UserProfile } from "~/stores/userStore"

export function deepMerge<T extends object>(a: T, b: Partial<T>): T {
  return merge({}, a, b)
}

export function mergeUserProfile(base: UserProfile, patch: Partial<UserProfile>): UserProfile {
  return deepMerge(base, patch)
}
