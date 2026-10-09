import type { Register } from 'claude-code'

import { decorate } from './lib/decorate'

// フックが例外を投げると入力のたびに通知が出る。装飾は付かないだけで済ませる
const safeDecorate = (text: string) => {
  try {
    return decorate(text)
  } catch {
    return []
  }
}

export const register: Register = (on) => {
  on('prompt.edit', async (_$, e, next) => {
    const box = await next(e)

    return { ...box, decorations: [...(box.decorations ?? []), ...safeDecorate(box.text)] }
  })

  // replace以外はe.textが下書き全体ではなく、オフセットがずれる
  on('prompt.fill', (_$, e, next) => {
    if (e.mode !== 'replace') {
      return next(e)
    }

    return next({ ...e, decorations: [...(e.decorations ?? []), ...safeDecorate(e.text)] })
  })
}
