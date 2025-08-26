export interface IEvent {
  title: string
  details: string[]
  company: string
  location: string
  startDate: string
  endDate: string
}

export interface IArticle {
  title: string
  description: string
  path: string
  publishedAt: string
  slug: string
  url: string
  cover: string
  author: {
    name: string
    url: string
    avatar: string
  }
}

export interface ISong {
  title: string
  file: string
  album: string
  platform: string
  publishedAt: string
  cover: string
  author: string
}

export interface IGood {
  title: string
  url: string
  description: string
  cover: string
  category: string
}
