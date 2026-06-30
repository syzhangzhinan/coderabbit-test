import { createClient, type SupabaseClient } from '@supabase/supabase-js'

// 问题：全局单例在 SSR 下跨请求共享状态
let supabaseInstance: SupabaseClient | null = null

export const useSupabase = () => {
  const config = useRuntimeConfig()

  if (!supabaseInstance) {
    supabaseInstance = createClient(
      config.public.supabaseUrl as string,
      config.public.supabaseAnonKey as string
    )
  }

  const uploadFile = async (bucket: string, path: string, file: File) => {
    // 问题：没有文件类型和大小验证
    const { data, error } = await supabaseInstance!.storage
      .from(bucket)
      .upload(path, file)

    if (error) throw error
    return data
  }

  const getPublicUrl = (bucket: string, path: string) => {
    // 问题：路径拼接没有安全校验
    const { data } = supabaseInstance!.storage
      .from(bucket)
      .getPublicUrl(path)

    return data.publicUrl
  }

  return { client: supabaseInstance!, uploadFile, getPublicUrl }
}
