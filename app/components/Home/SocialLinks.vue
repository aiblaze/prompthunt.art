<script lang="ts" setup>
const links = [
  {
    name: 'Twitter',
    url: 'https://twitter.com/mamboer',
    icon: 'mdi:twitter',
  },
  {
    name: 'GitHub',
    url: 'https://github.com/mamboer',
    icon: 'mdi:github',
  },
  {
    name: 'Telegram',
    url: 'https://t.me/mamboer',
    icon: 'mdi:telegram',
  },
]
</script>

<template>
  <div>
    <h2 class="uppercase text-xs font-semibold text-neutral-400 mb-4">
      FIND ME ON
    </h2>
    <div class="space-y-5">
      <NuxtLink
        v-for="link in links"
        :key="link.icon"
        :to="link.url"
        target="_blank"
        external
        class="flex items-end gap-4 dark:hover:text-neutral-300 group"
      >
        <span class="text-sm">
          {{ link.name }}
        </span>
        <div
          class="flex-1 border-b border-dashed border-gray-300 dark:border-gray-800 group-hover:border-gray-700"
        />
        <Icon :name="link.icon" class="w-6 h-6" />
      </NuxtLink>
    </div>
  </div>
</template>
