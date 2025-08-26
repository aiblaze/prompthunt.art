<script setup lang="ts">
import { useFixedHeader } from 'vue-use-fixed-header'

const { t } = useI18n()
const headerRef = ref(null)
const { styles } = useFixedHeader(headerRef)
const localePath = useLocalePath()

const items = computed(() => [
  { name: t('labels.home'), path: localePath('/'), icon: 'solar:home-smile-outline' },
  {
    name: t('labels.articles'),
    path: localePath('/articles'),
    icon: 'solar:document-add-outline',
  },
  {
    name: t('labels.bookmarks'),
    path: localePath('/bookmarks'),
    icon: 'solar:bookmark-linear',
    optional: true,
  },
  {
    name: t('labels.music'),
    path: localePath('/music'),
    icon: 'solar:music-note-2-outline',
  },
])
</script>

<template>
  <div ref="headerRef" :style="styles" class="fixed top-0 w-full z-50">
    <nav class="mx-auto px-4 sm:px-6 lg:px-8 max-w-2xl">
      <ul
        class="flex items-center my-4 px-3 text-sm font-medium text-neutral-800 rounded-full shadow-lg bg-white/90 shadow-gray-800/5 ring-1 backdrop-blur dark:bg-gray-800/90 dark:text-neutral-200 dark:ring-white/20 ring-gray-900/5"
      >
        <li v-for="item in items" :key="item.path" :class="{ 'hidden md:block': item.optional }">
          <UTooltip
            :text="item.name"
          >
            <ULink
              :to="item.path"
              class="relative px-3 py-4 flex items-center justify-center transition hover:text-primary-500 dark:hover:text-primary-400"
              active-class="text-primary-600 dark:text-primary-400"
            >
              <Icon aria-hidden="true" :name="item.icon" class="w-5 h-5 z-10" />
              <span
                v-if="$route.path === item.path"
                class="absolute inset-x-1 -bottom-px h-px bg-gradient-to-r from-primary-500/0 via-primary-500/70 to-primary-500/0 dark:from-primary-400/0 dark:via-primary-400/40 dark:to-primary-400/0"
              />
              <span
                v-if="$route.path === item.path"
                class="absolute h-8 w-8 z-0 rounded-full bg-gray-100 dark:bg-white/10 top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"
              />
              <span class="sr-only">{{ item.name }}</span>
            </ULink>
          </UTooltip>
        </li>
        <li class="flex-1" />
        <li>
          <AppLangSwitcher />
        </li>
        <li>
          <AppThemeToggle />
        </li>
      </ul>
    </nav>
  </div>
</template>
