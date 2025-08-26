<script setup lang="ts">
import type { Collections } from '@nuxt/content'
import type { IArticle } from '~/types'

const { t, locale } = useI18n()
const title = t('pageArticles.title')
const description = t('pageArticles.desc')
const prefix = locale.value === 'zh' ? '' : locale.value
useSeoMeta({
  title: `${title} - ${t('author.name')}`,
  description,
})

const collectionKey = `articles${prefix.toUpperCase()}` as keyof Collections

const { data } = await useAsyncData(() => {
  console.warn('queryCollection', collectionKey)
  return queryCollection(collectionKey)
    .all()
})

const articles = computed(() => {
  const items = useConvert<IArticle[]>(data.value ?? [])
  return items.sort((a, b) => {
    return new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime()
  })
})
</script>

<template>
  <main class="main">
    <AppHeader class="mb-16" :title="title" :description="description" />
    <ul v-if="articles" class="space-y-8">
      <li v-for="(article, id) in articles" :key="id">
        <AppArticleCard :article="article" />
      </li>
    </ul>
  </main>
</template>
