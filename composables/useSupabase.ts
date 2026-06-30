import { createClient, type SupabaseClient } from '@supabase/supabase-js'

const ALLOWED_FILE_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
const MAX_FILE_SIZE = 10 * 1024 * 1024 // 10MB

export const useSupabase = () => {
  const config = useRuntimeConfig()
  const client = useState<SupabaseClient | null>('supabase-client', () => null)

  if (!client.value) {
    client.value = createClient(
      config.public.supabaseUrl as string,
      config.public.supabaseAnonKey as string
    )
  }

  const uploadFile = async (bucket: string, path: string, file: File) => {
    if (!ALLOWED_FILE_TYPES.includes(file.type)) {
      throw new Error(`不支持的文件类型: ${file.type}`)
    }
    if (file.size > MAX_FILE_SIZE) {
      throw new Error('文件大小不能超过 10MB')
    }

    const safePath = path.replace(/\.\./g, '').replace(/^\//, '')
    const { data, error } = await client.value!.storage
      .from(bucket)
      .upload(safePath, file)

    if (error) throw error
    return data
  }

  const getPublicUrl = (bucket: string, path: string) => {
    const safePath = path.replace(/\.\./g, '').replace(/^\//, '')
    const { data } = client.value!.storage
      .from(bucket)
      .getPublicUrl(safePath)

    return data.publicUrl
  }

  return { client: client.value!, uploadFile, getPublicUrl }
}
