import type { EventHandler, EventHandlerRequest } from 'h3'
import type { IArticle } from '~/types'
import { Feed } from 'feed'
import { queryArticles } from './queryArticles'

export function feedHandler<T extends EventHandlerRequest, D>(handler: EventHandler<T, D>): EventHandler<T, D> {
  return defineEventHandler<T>(async (event) => {
    try {
      // Do something before the route handler
      // Set header
      event.node.res.setHeader('content-type', 'text/xml')

      await handler(event)

      // Do something after the route handler
      // Get feed language
      const lang = (event.node.res.getHeader('feed-lang') ?? 'en').toString()
      // Get articles
      const articles = await queryArticles(event, lang)

      // Generate feed
      const feed = buildFeed(articles, lang)

      return feed
    }
    catch (err) {
      // Error handling
      console.warn(err)
      return { err }
    }
  })
}

function buildFeed(posts: IArticle[], lang?: string) {
  const author = {
    name: '硅人8（PROMPTHUNT）',
    url: 'https://prompthunt.art',
  }
  const feed = new Feed({
    title: '硅人语言艺术（PROMPTHUNT.ART）',
    description: '聚焦全球 AI 提示词（prompt），帮助大家高效用好 AI。关注硅人语言艺术，硅人世界触手可得！',
    id: 'https://prompthunt.art/articles',
    link: 'https://prompthunt.art/articles',
    language: lang ?? 'en',
    image: 'https://prompthunt.art/apple-touch-icon.png',
    favicon: 'https://prompthunt.art/favicon.ico',
    copyright: `All rights reserved 2025 ~ ${new Date().getFullYear()}, PROMPTHUNT.ART`,
    feedLinks: {
      'rss': 'https://prompthunt.art/rss.xml',
      'rss-cn': 'https://prompthunt.art/rss-cn.xml',
    },
    author: {
      name: author.name,
      link: author.url,
    },
  })

  posts.forEach((post) => {
    const postAuthor = post.author ?? author
    feed.addItem({
      title: post.title,
      id: post.slug,
      link: post.path,
      description: post.description,
      author: [
        {
          name: postAuthor.name,
          link: postAuthor.url,
        },
      ],
      date: new Date(post.publishedAt),
    })
  })

  feed.addCategory('AI')
  feed.addCategory('AI 科学')
  feed.addCategory('AI 项目')
  feed.addCategory('AI 产品')
  feed.addCategory('AI 开源')
  feed.addCategory('AI 音乐')
  feed.addCategory('AI 艺术')
  feed.addCategory('AI 人工智能')
  feed.addCategory('AI 机器人')
  feed.addCategory('AI 智能')
  feed.addCategory('AI 提示词')
  feed.addCategory('AI 语言')

  return feed.rss2()
}
