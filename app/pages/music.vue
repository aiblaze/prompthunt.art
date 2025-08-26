<script setup lang="ts">
import type { Collections } from '@nuxt/content'
import type { Song } from '~/components/LevinPlayer/player'
import type { ISong } from '~/types'
import { Player } from '~/components/LevinPlayer/player'

const { t } = useI18n()
const title = t('pageMusic.title')
const description = t('pageMusic.desc')
const isPlaying = ref(false)

useSeoMeta({
  title: `${title} | ${t('author.name')}`,
  description,
})

// const prefix = useI18n().locale.value === 'en' ? 'EN' : ''

const collectionKey = `music` as keyof Collections
const { data } = await useAsyncData('music-home', () =>
  queryCollection(collectionKey)
    .order('publishedAt' as any, 'DESC')
    .all())

const items = computed(() => {
  const items1 = useConvert<ISong[]>(data.value ?? [])
  return items1
})

const playList = ref<Song[]>()
const xplayer = ref<Player>()
function toggleSong(index: number) {
  if (xplayer.value?.index === index) {
    if (isPlaying.value) {
      xplayer.value?.pause()
      isPlaying.value = false
    }
    else {
      xplayer.value?.play()
      isPlaying.value = true
    }
    return
  }
  isPlaying.value = true
  xplayer.value?.skipTo(index)
}
watchEffect(() => {
  const items1 = items.value ?? []
  playList.value = items1.map(item => ({
    title: item.title ?? '',
    author: item.author ?? '',
    file: item.file ?? '',
  }))
  xplayer.value = new Player(playList.value)
})

onBeforeRouteLeave(() => {
  xplayer.value?.pause()
})
</script>

<template>
  <main class="main">
    <AppHeader
      class="mb-12"
      :title="title"
      :description="description"
    />
    <ul class="space-y-2">
      <li v-for="(item, index) in items" :key="item.file">
        <a
          :href="item.file"
          class="flex items-center gap-3 hover:bg-gray-100 dark:hover:bg-white/10 p-2 rounded-lg -m-2 text-sm min-w-0"
          :class="{ '!bg-primary': xplayer?.index === index && isPlaying }"
          @click.prevent="toggleSong(index)"
        >
          <Icon :name="(!isPlaying || xplayer?.index !== index) ? 'mdi:play-circle' : 'mdi:pause-circle'" class="text-xl" />
          <UAvatar
            :src="item.cover"
            :alt="item.title"
          />
          <p class="truncate text-neutral-700 dark:text-neutral-300">
            {{ item.title }}
          </p>
          <span class="flex-1" />
          <span class="text-xs font-medium text-neutral-700 dark:text-neutral-300">
            {{ `<${item.album}>` }}
          </span>
        </a>
      </li>
    </ul>
  </main>
</template>
