// If ts complains things like `Object literal may only specify known properties, and 'feed' does not exist in type 'InputConfig<NuxtConfig, ConfigLayerMeta>'`
// Run `pnpm update -D`
export default defineNuxtConfig({
  compatibilityDate: '2025-08-26',
  devtools: { enabled: true },
  nitro: {
    prerender: {
      routes: [
        '/rss.xml',
        '/rss-cn.xml',
      ],
    },
  },
  fonts: {
    // Use BunnyCDN for fonts
    provider: 'bunny',
  },
  modules: [
    '@nuxtjs/i18n',
    '@nuxt/ui',
    '@nuxtjs/google-fonts',
    '@nuxt/image',
    '@nuxt/content',
    '@vueuse/nuxt',
    'nuxt-module-feed',
  ],
  css: [
    '~/assets/css/global.css',
  ],
  app: {
    pageTransition: { name: 'page', mode: 'out-in' },
    head: {
      htmlAttrs: {
        lang: 'zh',
        class: 'h-full',
      },
      bodyAttrs: {
        class: 'antialiased bg-gray-50 dark:bg-black min-h-screen h-full',
      },
      link: [
        { rel: 'apple-touch-icon', sizes: '180x180', href: '/apple-touch-icon.png' },
        { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/favicon-32x32.png' },
        { rel: 'icon', type: 'image/png', sizes: '16x16', href: '/favicon-16x16.png' },
        { rel: 'manifest', href: '/site.webmanifest' },
      ],
    },
  },
  googleFonts: {
    display: 'swap',
    families: {
      Inter: [400, 500, 600, 700, 800, 900],
    },
  },
  i18n: { // i18n configuration
    locales: [
      {
        code: 'en',
        name: 'English',
        file: 'en-US.json',
      },
      {
        code: 'zh',
        name: '中文',
        file: 'zh-CN.json',
      },
    ],
    defaultLocale: 'zh',
    strategy: 'prefix_except_default',
  },
  feed: {
    sources: [
      {
        path: '/feed.xml',
        type: 'rss2',
        cacheTime: 60 * 15,
      },
    ],
  },
})
