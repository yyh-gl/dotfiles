import type { On, PromptDecoration, PromptFillInput } from 'claude-code'
import { describe, expect, test, type Engine } from 'claude-code/testing'

import { CODE_COLOR, MAX_CHARS } from './lib/palette'

// prompt.editはテストキットから発火できないため、同じ装飾をprompt.fillで検証する。
// prompt.editへの配線はステップ6の実機確認（e）で見る。
// decorateが例外を投げた場合のフォールバックは、decorateを差し替えられないため自動テストできない。

const FENCED = '```ts\nconst a = 1\n```'
const CODE_RUN: PromptDecoration = { start: 6, end: 17, color: CODE_COLOR }
const EXISTING: PromptDecoration = { start: 0, end: 3, underline: true }

const fillReachingBox = async ($: Engine, on: On, args: Omit<PromptFillInput, 'origin'>) => {
  let reached: PromptFillInput | undefined

  on('prompt.fill', (_$, e) => {
    reached = e

    return { isFilled: true }
  })
  await $.prompt.fill({ ...args, origin: { kind: 'plugin', name: 'test' } })

  return reached
}

describe('prompt.fill', () => {
  test('replaceの下書きにコード色の装飾を足す', async ($, on) => {
    const reached = await fillReachingBox($, on, { text: FENCED, mode: 'replace' })

    expect(reached?.decorations).toContainEqual(CODE_RUN)
  })

  for (const mode of ['append', 'insert'] as const) {
    test(`${mode}では装飾を足さない`, async ($, on) => {
      const reached = await fillReachingBox($, on, { text: FENCED, mode })

      expect(reached?.decorations ?? []).toEqual([])
    })
  }

  test('呼び出し側の装飾を保ったまま足す', async ($, on) => {
    const reached = await fillReachingBox($, on, { text: FENCED, mode: 'replace', decorations: [EXISTING] })

    expect(reached?.decorations).toEqual(expect.arrayContaining([EXISTING, CODE_RUN]))
  })

  test('記法のない下書きでは呼び出し側の装飾を変えない', async ($, on) => {
    const reached = await fillReachingBox($, on, { text: 'plain', mode: 'replace', decorations: [EXISTING] })

    expect(reached?.decorations).toEqual([EXISTING])
  })

  test('装飾以外の値はそのまま通す', async ($, on) => {
    const reached = await fillReachingBox($, on, { text: FENCED, mode: 'replace' })

    expect(reached).toEqual(expect.objectContaining({ text: FENCED, mode: 'replace' }))
  })

  test('60,000文字を超える下書きには装飾を足さない', async ($, on) => {
    const text = `# ${'a'.repeat(MAX_CHARS)}`
    const reached = await fillReachingBox($, on, { text, mode: 'replace', decorations: [EXISTING] })

    expect(reached?.decorations).toEqual([EXISTING])
  })

  test('足した装飾の範囲は下書きに収まり、改行をまたがない', async ($, on) => {
    const text = '# 見出し\n```\n日本語 😀\n```\n- `code`'
    const reached = await fillReachingBox($, on, { text, mode: 'replace' })

    expect(reached?.decorations?.length).toBeGreaterThan(0)
    for (const { start, end } of reached?.decorations ?? []) {
      expect(start).toBeGreaterThanOrEqual(0)
      expect(end).toBeLessThanOrEqual(text.length)
      expect(end).toBeGreaterThan(start)
      expect(text.slice(start, end)).not.toMatch(/[\r\n]/)
    }
  })
})
