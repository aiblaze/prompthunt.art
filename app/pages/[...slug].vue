<script setup lang="ts">
import type { Collections } from '@nuxt/content'

const { t } = useI18n()

useSeoMeta({
  twitterCard: 'summary_large_image',
  articleAuthor: [t('author.name')],
})

const collectionKey = `content` as keyof Collections
const route = useRoute()
const { data: doc } = await useAsyncData(route.path, () => {
  return queryCollection(collectionKey).path(route.path).first()
})
</script>

<template>
  <main class="main">
    <ProseWrapper>
      <article v-if="doc">
        <h1>{{ doc.title }}</h1>

        <ContentRenderer :value="doc" />
      </article>
    </ProseWrapper>
  </main>
</template>

<style>
.prose h2 a,
.prose h3 a {
  @apply no-underline;
}
</style>
