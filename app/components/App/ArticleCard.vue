<script setup lang="ts">
import type { IArticle } from '~/types'

defineProps({
  article: {
    type: Object as PropType<IArticle>,
    required: true,
  },
})

function getReadableDate(dateString: string) {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}
</script>

<template>
  <NuxtLink :to="article.path" class="group">
    <article class="flex flex-col gap-1">
      <h2
        class="text-base font-semibold font-display tracking-tight text-neutral-800 dark:text-neutral-100 group-hover:text-primary-600"
      >
        {{ article.title }}
      </h2>
      <div class="flex items-center text-sm text-neutral-500 dark:text-neutral-400 gap-2">
        <UAvatar
          size="3xs"
          :src="article.author.avatar"
          :alt="article.author.name"
        />
        <span>{{ article.author.name }}</span>
        <time
          class="flex items-center"
          datetime="2022-09-05"
        ><span
           class="absolute inset-y-0 left-0 flex items-center"
           aria-hidden="true"
         ><span
           class="h-4 w-0.5 rounded-full bg-gray-200 dark:bg-gray-500"
         /></span>
          {{ getReadableDate(article.publishedAt) }}
        </time>
      </div>
      <p class="relative z-10 text-sm text-neutral-700 dark:text-neutral-400">
        {{ article.description }}
      </p>
    </article>
  </NuxtLink>
</template>
