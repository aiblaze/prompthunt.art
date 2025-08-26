<script setup>
defineProps({
  title: String,
  description: String,
  showUsageTab: {
    type: Boolean,
    default: true,
  },
  showCreditTab: {
    type: Boolean,
    default: false,
  },
})

const tab = ref('preview')
</script>

<template>
  <div>
    <h2 class="text-sm font-semibold">
      {{ title }}
    </h2>
    <p class="text-neutral-500 text-sm">
      {{ description }}
    </p>
    <div
      class="mt-2 border dark:border-white/10 rounded-lg shadow-sm overflow-hidden"
    >
      <div class="p-2 flex items-center gap-2 border-b dark:border-white/10">
        <div class="flex items-center w-full">
          <UButton
            label="Preview"
            variant="soft"
            color="white"
            size="xs"
            class="relative hover:bg-neutral-100 hover:text-neutral-600 dark:hover:bg-neutral-800 dark:hover:text-neutral-300"
            :class="{ 'active-tab': tab === 'preview' }"
            @click="tab = 'preview'"
          />
          <UButton
            label="Code"
            variant="soft"
            color="white"
            size="xs"
            class="relative hover:bg-neutral-100 hover:text-neutral-600 dark:hover:bg-neutral-800 dark:hover:text-neutral-300"
            :class="{ 'active-tab': tab === 'code' }"
            @click="tab = 'code'"
          />
          <UButton
            v-if="showUsageTab"
            label="Usage"
            variant="soft"
            color="white"
            size="xs"
            class="relative hover:bg-neutral-100 hover:text-neutral-600 dark:hover:bg-neutral-800 dark:hover:text-neutral-300"
            :class="{ 'active-tab': tab === 'usage' }"
            @click="tab = 'usage'"
          />
          <UButton
            v-if="showCreditTab"
            label="Credits"
            variant="soft"
            color="white"
            size="xs"
            class="relative hover:bg-neutral-100 hover:text-neutral-600 dark:hover:bg-neutral-800 dark:hover:text-neutral-300"
            :class="{ 'active-tab': tab === 'credit' }"
            @click="tab = 'credit'"
          />
        </div>
      </div>
      <div>
        <div
          v-if="tab === 'preview'"
          class="bg-neutral-100 dark:bg-neutral-900 overflow-hidden"
        >
          <slot name="preview" />
        </div>
        <slot v-if="tab === 'code'" name="codebase" />
        <slot v-if="tab === 'usage'" name="usage" />
        <slot v-if="tab === 'credit'" name="credit" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.active-tab {
  position: relative;
}
.active-tab::after {
  content: '';
  position: absolute;
  width: 100%;
  height: 2px;
  background-color: var(--ui-primary);
  bottom: -9px;
  left: 0;
  pointer-events: none;
}
</style>
