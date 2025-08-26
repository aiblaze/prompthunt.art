<script setup>
const { t } = useI18n()
useSeoMeta({
  title: t('author.name'),
  description: t('author.desc'),
})
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center">
      <div class="p-2 ring-1 border ring-blue-600 border-blue-700 dark:ring-white/10 dark:border-slate-800 hover:ring-2 transition-all duration-300 bg-slate-950 rounded-full h-12 w-12 sm:h-16 sm:w-16 flex items-center justify-center">
        <NuxtImg src="/logo.svg" alt="AIFIRE" placeholder />
      </div>
      <div class="ml-3">
        <h1 class="uppercase text-2xl font-bold tracking-tight text-neutral-800 dark:text-neutral-100">
          {{ $t('author.name') }}
        </h1>
        <p class="text-neutral-800 dark:text-neutral-300 text-sm">
          {{ $t('author.title') }}
        </p>
      </div>
    </div>
    <p class="text-neutral-900 dark:text-neutral-400">
      {{ $t('author.desc') }}
    </p>
  </div>
</template>
