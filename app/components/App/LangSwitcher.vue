<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const icons = {
  en: '🇺🇸',
  zh: '🇨🇳',
}

const { locale, locales, setLocale } = useI18n()
const items = locales.value.map(item => ({
  label: item.name ?? item.code.toUpperCase(),
  icon: icons[item.code as keyof typeof icons] || '🇨🇳',
  value: item.code,
}))

const selectedLanguage = ref(locale.value)

watch(selectedLanguage, (newVal) => {
  if (newVal) {
    setLocale(newVal)
  }
})
</script>

<template>
  <div class="md:pr-3 flex items-center justify-center">
    <USelectMenu
      v-model="selectedLanguage"
      :items="items"
      size="xs"
      value-key="value"
      class="w-auto"
      :search-input="false"
    >
      <template #leading>
        <span class="mr-2">{{ items.find(i => i.value === selectedLanguage)?.icon }}</span>
      </template>

      <template #item="{ item }">
        <span class="text-xs">{{ item.icon }} {{ item.label }}</span>
      </template>
    </USelectMenu>
  </div>
</template>
