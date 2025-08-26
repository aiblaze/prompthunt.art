<script setup lang="ts">
const { t } = useI18n()

const description = t('pageBookmarks.desc')
const title = t('pageBookmarks.title')
useSeoMeta({
  title: `${title} | ${t('author.name')}`,
  description,
})

const bookmarks = [
  {
    id: 1,
    label: 'DeepSeek',
    url: 'https://www.deepseek.com',
  },
  {
    id: 2,
    label: '豆包',
    url: 'https://www.doubao.com/',
  },
]

function getHost(url: string) {
  const parsedUrl = new URL(url)
  let host = parsedUrl.host
  if (host.startsWith('www.')) {
    host = host.substring(4)
  }
  return host
}

function getThumbnail(url: string) {
  const host = getHost(url)
  return `https://favicon.io/favicon/${host}`
}
</script>

<template>
  <main class="main">
    <AppHeader class="mb-8" :title="title" :description="description" />
    <ul class="space-y-2">
      <li v-for="bookmark in bookmarks" :key="bookmark.id">
        <a
          :href="bookmark.url"
          target="_blank"
          class="flex items-center gap-3 hover:bg-gray-100 dark:hover:bg-white/10 p-2 rounded-lg -m-2 text-sm min-w-0"
        >
          <UAvatar
            :src="getThumbnail(bookmark.url)"
            :alt="bookmark.label"
          />
          <p class="truncate text-neutral-700 dark:text-neutral-200">
            {{ bookmark.label }}
          </p>
          <span class="flex-1" />
          <span class="text-xs font-medium text-neutral-400 dark:text-neutral-600">
            {{ getHost(bookmark.url) }}
          </span>
        </a>
      </li>
    </ul>
  </main>
</template>
