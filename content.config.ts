import { defineCollection, defineContentConfig, z } from '@nuxt/content'

const commonSchema = z.object({
  title: z.string(),
  description: z.string(),
  path: z.string(),
  publishedAt: z.string(),
  cover: z.string(),
  url: z.string(),
  author: z.object({
    name: z.string(),
    url: z.string(),
    avatar: z.string(),
  }),
})

const eventSchema = z.object({
  title: z.string(),
  details: z.array(z.string()),
  company: z.string(),
  location: z.string(),
  startDate: z.string(),
  endDate: z.string(),
})

const songSchema = z.object({
  title: z.string(),
  file: z.string(),
  album: z.string(),
  platform: z.string(),
  publishedAt: z.string(),
  cover: z.string(),
  author: z.string(),
})

const goodsSchema = z.object({
  title: z.string(),
  url: z.string(),
  description: z.string(),
  cover: z.string(),
  category: z.string(),
})

export default defineContentConfig({
  collections: {
    content: defineCollection({
      source: {
        include: '**',
      },
      type: 'page',
      schema: commonSchema,
    }),
    articles: defineCollection({
      source: {
        include: 'articles/**',
      },
      // Specify the type of content in this collection
      type: 'page',
      schema: commonSchema,
    }),
    projects: defineCollection({
      source: {
        include: 'projects/**',
      },
      // Specify the type of content in this collection
      type: 'page',
      schema: commonSchema,
    }),
    events: defineCollection({
      source: {
        include: 'events/**',
      },
      // Specify the type of content in this collection
      type: 'data',
      schema: eventSchema,
    }),
    goods: defineCollection({
      source: {
        include: 'goods/**',
      },
      // Specify the type of content in this collection
      type: 'data',
      schema: goodsSchema,
    }),
    labs: defineCollection({
      source: {
        include: 'labs/**',
      },
      // Specify the type of content in this collection
      type: 'page',
      schema: commonSchema,
    }),
    music: defineCollection({
      source: {
        include: 'music/**',
      },
      // Specify the type of content in this collection
      type: 'data',
      schema: songSchema,
    }),
    // EN
    articlesEN: defineCollection({
      source: {
        include: 'en/articles/**',
      },
      type: 'page',
      schema: commonSchema,
    }),
    projectsEN: defineCollection({
      source: {
        include: 'en/projects/**',
      },
      type: 'page',
      schema: commonSchema,
    }),
    eventsEN: defineCollection({
      source: {
        include: 'en/events/**',
      },
      type: 'data',
      schema: eventSchema,
    }),
    goodsEN: defineCollection({
      source: {
        include: 'en/goods/**',
      },
      type: 'data',
      schema: goodsSchema,
    }),
  },
})
