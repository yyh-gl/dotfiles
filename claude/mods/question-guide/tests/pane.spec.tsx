import { beforeAll, describe, expect, test } from 'bun:test'

import { paneView } from '../hooks/pane'
import type { Entry } from '../types'

type Node = { type: unknown; props: Record<string, unknown> | null; children: unknown[] }

beforeAll(() => {
  Object.assign(globalThis, {
    h: (type: unknown, props: Record<string, unknown> | null, ...children: unknown[]) => ({ type, props, children }),
    Fragment: 'Fragment',
  })
})

const ui = { Box: 'Box', Text: 'Text', Button: 'Button' } as never

const textOf = (node: unknown): string[] => {
  if (Array.isArray(node)) {
    return node.flatMap(textOf)
  }
  if (typeof node === 'string' || typeof node === 'number') {
    return [String(node)]
  }
  if (node === null || typeof node !== 'object') {
    return []
  }

  return ((node as Node).children ?? []).flatMap(textOf)
}

const entry = (overrides: Partial<Entry> = {}): Entry => ({
  id: 'e1',
  kind: 'dialog',
  items: [{ question: 'どれにしますか？', header: '方式', multiSelect: false, options: [{ label: 'A案' }] }],
  prompts: ['認証を実装して'],
  lead: '直前の説明です',
  state: 'pending',
  answers: {},
  explanation: { status: 'idle', text: '', runId: 0 },
  ...overrides,
})

const actions = { moveTo: () => () => {}, toggleHistory: () => {}, toggleAi: () => {}, explain: () => {} }

const model = (entries: Entry[], overrides = {}) => ({
  entries,
  cursor: 0,
  isAiOn: true,
  showHistory: false,
  columns: 40,
  bodyRows: 20,
  ...overrides,
})

const render = (entries: Entry[], overrides = {}) => textOf(paneView(ui, model(entries, overrides), actions)).join('\n')

describe('paneView', () => {
  test('質問がなければ空の案内を表示する', () => {
    expect(render([])).toContain('まだ質問はありません')
  })

  test('回答待ちのダイアログでも生成済みのAI解説を表示する', () => {
    const view = render([entry({ explanation: { status: 'done', text: '解説の本文です', runId: 1 } })])

    expect(view).toContain('解説の本文です')
  })

  test('回答待ちのダイアログは行数予算に収まり、指示→解説→直前の説明の順に並ぶ', () => {
    const big = entry({
      lead: Array.from({ length: 50 }, (_, i) => `説明${i}`).join('\n'),
      explanation: { status: 'done', text: Array.from({ length: 50 }, (_, i) => `解説${i}`).join('\n'), runId: 1 },
    })
    const tree = paneView(ui, model([big], { bodyRows: 16 }), actions) as Node
    const rows = (tree.children as unknown[]).flat()
    const text = textOf(tree).join('\n')

    expect(rows.length).toBeLessThanOrEqual(16)
    expect(text.indexOf('認証を実装して')).toBeLessThan(text.indexOf('解説0'))
    expect(text.indexOf('解説0')).toBeLessThan(text.indexOf('説明49'))
    expect(text).toContain('説明49')
  })

  test('回答後と文章の質問の表示にも最近の指示と直前の説明を載せる', () => {
    const answered = render([entry({ state: 'answered' })])
    const text = render([entry({ kind: 'text', state: 'pending' })])

    for (const view of [answered, text]) {
      expect(view).toContain('認証を実装して')
      expect(view).toContain('直前の説明です')
    }
  })

  test('履歴一覧は各質問を状態つきの1行で表示する', () => {
    const multiline = entry({ id: 'e2', state: 'cancelled', items: [{ question: '1行目\n2行目？', header: '', multiSelect: false, options: [] }] })
    const view = render([entry(), multiline], { showHistory: true, cursor: 1 })

    expect(view).toContain('質問の履歴')
    expect(view).toContain('[回答待ち]')
    expect(view).toContain('[中断] 1行目 2行目？')
  })

  test('bodyRowsと指示の件数がどんな組み合わせでも、コンパクト表示の行数はbodyRows以下', () => {
    const longPrompt = '長い指示です。'.repeat(30)
    const lead = Array.from({ length: 40 }, (_, i) => `説明${i}`).join('\n')
    const explanation = { status: 'done' as const, text: Array.from({ length: 40 }, (_, i) => `解説${i}`).join('\n'), runId: 1 }

    for (let bodyRows = 8; bodyRows <= 30; bodyRows++) {
      for (let count = 0; count <= 3; count++) {
        const prompts = Array.from({ length: count }, () => longPrompt)
        const tree = paneView(ui, model([entry({ prompts, lead, explanation })], { bodyRows, columns: 100 }), actions) as Node
        const rows = (tree.children as unknown[]).flat().length

        expect({ bodyRows, count, fits: rows <= bodyRows }).toEqual({ bodyRows, count, fits: true })
      }
    }
  })

  test('生成中と失敗の状態を表示する', () => {
    expect(render([entry({ explanation: { status: 'loading', text: '', runId: 1 } })])).toContain('解説を生成中')
    expect(render([entry({ explanation: { status: 'failed', text: '', runId: 1 } })])).toContain('生成できませんでした')
  })
})
