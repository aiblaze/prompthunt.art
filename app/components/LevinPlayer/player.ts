import { Howl, Howler } from 'howler'

export interface Song {
  title: string
  file: string
  howl?: Howl
}
/**
 * Player class
 */
export class Player {
  playlist: Song[]
  index: number

  constructor(playlist: Song[]) {
    this.playlist = playlist
    this.index = 0
  }

  play(index?: number) {
    let sound: Howl

    index = typeof index === 'number' ? index : this.index
    const data = this.playlist[index]

    if (data.howl) {
      sound = data.howl
    }
    else {
      sound = data.howl = new Howl({
        src: [data.file],
        html5: true,
        onplay: () => {
          requestAnimationFrame(this.step.bind(this))
        },
        onload: () => {},
        onend: () => {
          this.skip('next')
        },
        onpause: () => {},
        onstop: () => {},
        onseek: () => {
          requestAnimationFrame(this.step.bind(this))
        },
      })
    }

    sound.play()
    this.index = index
  }

  pause() {
    const sound = this.playlist[this.index].howl
    if (sound) {
      sound.pause()
    }
  }

  skip(direction: 'next' | 'prev') {
    let index = 0
    if (direction === 'prev') {
      index = this.index - 1
      if (index < 0) {
        index = this.playlist.length - 1
      }
    }
    else {
      index = this.index + 1
      if (index >= this.playlist.length) {
        index = 0
      }
    }

    this.skipTo(index)
  }

  skipTo(index: number) {
    const currentSong = this.playlist[this.index]
    if (currentSong.howl) {
      currentSong.howl.stop()
    }

    this.play(index)
  }

  volume(val: number) {
    Howler.volume(val)
  }

  seek(per: number) {
    const sound = this.playlist[this.index].howl
    if (sound && sound.playing()) {
      sound.seek(sound.duration() * per)
    }
  }

  step() {
    const sound = this.playlist[this.index].howl
    if (sound && sound.playing()) {
      requestAnimationFrame(this.step.bind(this))
    }
  }

  formatTime(secs: number): string {
    const minutes = Math.floor(secs / 60) || 0
    const seconds = (secs - minutes * 60) || 0

    return `${minutes}:${seconds < 10 ? '0' : ''}${seconds}`
  }
}
