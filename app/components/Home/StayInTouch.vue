<template>
  <div class="space-y-6">
    <div class="flex items-center gap-2">
      <div
        class="flex-none rounded-full p-1 text-primary-500 bg-primary-500/10"
      >
        <div class="h-1.5 w-1.5 rounded-full bg-current" />
      </div>
      <h2 class="uppercase text-sm font-semibold text-neutral-500 dark:text-neutral-400">
        {{ $t('labels.stayInTouch') }}
      </h2>
    </div>
    <div class="flex flex-wrap items-center gap-6 justify-between">
      <div class="mt-6 flex grow items-center flex-col relative bg-gradient-to-b from-[#C59BA7] to-[#B9A4BF] rounded" :title="$t('labels.wechat')">
        <div class="left-[50%] -ml-5 -top-5 flex justify-center items-center w-10 h-10 absolute rounded-full bg-white border border-[#C59BA7]">
          <UIcon name="i-mdi-wechat" class="w-7 h-7 text-[#24C891]" />
        </div>
        <div class="flex text-center items-center justify-center w-40 max-w-full h-48 text-white">
          <NuxtImg src="/wechat.jpg" alt="WeChat QR Code" class="w-40 rounded max-w-full" />
        </div>
      </div>
      <div class="mt-6 flex grow items-center flex-col relative bg-gradient-to-b from-[#C59BA7] to-[#B9A4BF] rounded" :title="$t('labels.email')">
        <div class="left-[50%] -ml-5 -top-5 flex justify-center items-center w-10 h-10 absolute rounded-full bg-[#f4f2ed] border border-[#C59BA7]">
          <Icon name="i-mdi-email-outline" class="w-7 h-7 text-blue-700" />
        </div>
        <div class="flex text-center items-center justify-center w-40 max-w-full h-48 text-white uppercase">
          aiblaze<br>[at]<br>126.com
        </div>
      </div>
    </div>
  </div>
</template>
