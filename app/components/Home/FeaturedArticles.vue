<script lang="ts" setup>
import type { Collections } from '@nuxt/content'
import type { IArticle } from '~/types'

const localePath = useLocalePath()
const { t, locale } = useI18n()
const allArticles = `${t('labels.allArticles')} →`
const urlArticle = localePath('/articles')
const prefix = locale.value === 'zh' ? '' : locale.value
const collectionKey = `articles${prefix.toUpperCase()}` as keyof Collections
const { data: items } = await useAsyncData(() => {
  console.warn('queryCollection', collectionKey)
  return queryCollection(collectionKey)
    .order('publishedAt' as any, 'DESC')
    .limit(5)
    .all()
})

const articles = computed(() => {
  return items.value?.map(item => useConvert<IArticle>(item))
})
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between text-sm font-semibold text-neutral-500 dark:text-neutral-400">
      <div class="flex items-center gap-2">
        <div
          class="flex-none rounded-full p-1 text-primary-500 bg-primary-500/10"
        >
          <div class="h-1.5 w-1.5 rounded-full bg-current" />
        </div>
        <h2 class="uppercase">
          {{ $t('labels.latestArticles') }}
        </h2>
      </div>
      <div class="flex items-center justify-center">
        <UButton
          :label="allArticles"
          :to="urlArticle"
          variant="link"
          color="neutral"
        />
      </div>
    </div>
    <ul class="space-y-8">
      <li v-for="(article, id) in articles" :key="id">
        <AppArticleCard :article="article" />
      </li>
    </ul>
  </div>
</template>
