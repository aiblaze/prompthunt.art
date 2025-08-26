export function useConvert<T>(data: any): T {
  return data as unknown as T
}
