import type { Collections } from '@nuxt/content'
import type { H3Event } from 'h3'
import type { IArticle } from '~/types'
import { useConvert } from '~/composables/useConvert'

export async function queryArticles(event: H3Event, lang: string = 'zh') {
  const prefix = lang === 'zh' ? '' : lang
  const collectionKey = `articles${prefix.toUpperCase()}` as keyof Collections

  const items = await queryCollection(event, collectionKey)
    .order('publishedAt' as any, 'DESC')
    .all()

  // Convert to IArticle[]
  const docs = items.map(item => useConvert<IArticle>(item))

  return docs
}
