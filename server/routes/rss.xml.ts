import { feedHandler } from '../utils/feedHandler'

export default feedHandler(async (event) => {
  event.node.res.setHeader('feed-lang', 'en')
})
