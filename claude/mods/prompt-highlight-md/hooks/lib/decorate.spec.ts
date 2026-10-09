import { describe, expect, test } from 'bun:test'

import { decorate } from './decorate'
import {
  CODE_COLOR,
  HEADING_COLOR,
  LIST_MARKER_COLOR,
  MAX_CHARS,
  TASK_DONE_COLOR,
  TASK_TODO_COLOR,
} from './palette'

const DIM = { dimColor: true }
const CODE = { color: CODE_COLOR }
const HEADING = { color: HEADING_COLOR, bold: true }
const LIST = { color: LIST_MARKER_COLOR }
const TODO = { color: TASK_TODO_COLOR }
const DONE = { color: TASK_DONE_COLOR }
const QUOTE = { italic: true }

const painted = (text: string) =>
  decorate(text).map(({ start, end, ...style }) => [text.slice(start, end), style])

describe('decorate', () => {
  test('空文字は装飾なし', () => {
    expect(decorate('')).toEqual([])
  })

  test('記法のない平文は装飾なし', () => {
    expect(decorate('hello world\nsecond line')).toEqual([])
  })

  describe('見出し', () => {
    test.each([1, 2, 3, 4, 5, 6])('#が%i個の見出しは記号がdim、本文が見出し色の太字', (level) => {
      const marker = '#'.repeat(level)

      expect(painted(`${marker} 見出し`)).toEqual([
        [marker, DIM],
        ['見出し', HEADING],
      ])
    })

    test('#が7個の行は見出しではない', () => {
      expect(painted('####### a')).toEqual([])
    })

    test('#の直後が空白でない行は見出しではない', () => {
      expect(painted('#tag')).toEqual([])
    })

    test('本文のない見出しは記号だけdim', () => {
      expect(painted('##')).toEqual([['##', DIM]])
    })

    test('4スペース字下げの行は見出しではない', () => {
      expect(painted('    # a')).toEqual([])
    })
  })

  describe('区切り線', () => {
    test.each(['---', '***', '___', '- - -', '----------', ' ---'])('%jは行全体がdim', (rule) => {
      expect(painted(rule)).toEqual([[rule, DIM]])
    })

    test('2個では区切り線ではない', () => {
      expect(painted('--')).toEqual([])
    })

    test('見出しの判定が区切り線より先', () => {
      expect(painted('# ---')).toEqual([
        ['#', DIM],
        ['---', HEADING],
      ])
    })
  })

  describe('リスト', () => {
    test.each(['-', '*', '+'])('%jの記号がリスト色', (marker) => {
      expect(painted(`${marker} item`)).toEqual([[marker, LIST]])
    })

    test.each([
      ['1.', '1. item'],
      ['10)', '10) item'],
    ])('番号%jの記号がリスト色', (marker, line) => {
      expect(painted(line)).toEqual([[marker, LIST]])
    })

    test('ネストしたリストでも記号がリスト色', () => {
      expect(painted('    - nested')).toEqual([['-', LIST]])
    })

    test('項目のない記号だけの行もリスト色', () => {
      expect(painted('-')).toEqual([['-', LIST]])
    })

    test('記号の直後が空白でなければリストではない', () => {
      expect(painted('-item')).toEqual([])
    })

    test('未完了タスクは[ ]がタスク未完了色', () => {
      expect(painted('- [ ] todo')).toEqual([
        ['-', LIST],
        ['[ ]', TODO],
      ])
    })

    test.each(['x', 'X'])('完了タスク[%s]はタスク完了色', (mark) => {
      expect(painted(`- [${mark}] done`)).toEqual([
        ['-', LIST],
        [`[${mark}]`, DONE],
      ])
    })

    test('[ ]の直後が空白でなければタスクではない', () => {
      expect(painted('- [ ]todo')).toEqual([['-', LIST]])
    })
  })

  describe('引用', () => {
    test('>はdim、本文は斜体', () => {
      expect(painted('> quote')).toEqual([
        ['>', DIM],
        ['quote', QUOTE],
      ])
    })

    test.each(['> > a', '>> a'])('ネスト%jの各>がdim', (line) => {
      expect(painted(line)).toEqual([
        ['>', DIM],
        ['>', DIM],
        ['a', QUOTE],
      ])
    })

    test('本文のない引用は>だけdim', () => {
      expect(painted('>')).toEqual([['>', DIM]])
    })

    test('引用の中の記法は色付けしない', () => {
      expect(painted('> - a')).toEqual([
        ['>', DIM],
        ['- a', QUOTE],
      ])
    })
  })

  describe('インラインコード', () => {
    test('対応するバッククォートごとコード色', () => {
      expect(painted('a `b` c')).toEqual([['`b`', CODE]])
    })

    test('閉じていないバッククォートは色付けしない', () => {
      expect(painted('a `b c')).toEqual([])
    })

    test('長さの違うバッククォートでは閉じない', () => {
      expect(painted('``a`b``')).toEqual([['``a`b``', CODE]])
    })

    test('改行をまたがない', () => {
      expect(painted('`a\nb`')).toEqual([])
    })

    test('見出しの本文では見出し色の太字を保ったままコード色にする', () => {
      expect(painted('# a `b` c')).toEqual([
        ['#', DIM],
        ['a ', HEADING],
        ['`b`', { ...HEADING, ...CODE }],
        [' c', HEADING],
      ])
    })

    test('リストの本文でもコード色', () => {
      expect(painted('- a `b`')).toEqual([
        ['-', LIST],
        ['`b`', CODE],
      ])
    })

    test('引用の本文では斜体を保ったままコード色にする', () => {
      expect(painted('> a `b`')).toEqual([
        ['>', DIM],
        ['a ', QUOTE],
        ['`b`', { ...QUOTE, ...CODE }],
      ])
    })

    test('コードフェンス内では二重に装飾しない', () => {
      expect(painted('```\n`a`\n```')).toEqual([
        ['```', DIM],
        ['`a`', CODE],
        ['```', DIM],
      ])
    })
  })

  describe('入力の癖', () => {
    test('CRLFでも行頭記法を認識し、範囲に改行を含めない', () => {
      expect(painted('# a\r\n```\r\nx\r\n```\r\n- b')).toEqual([
        ['#', DIM],
        ['a', HEADING],
        ['```', DIM],
        ['x', CODE],
        ['```', DIM],
        ['-', LIST],
      ])
    })

    test('単独のCRも改行として扱う', () => {
      expect(painted('# a\r- b')).toEqual([
        ['#', DIM],
        ['a', HEADING],
        ['-', LIST],
      ])
    })

    test('日本語の行でも範囲が本文と一致する', () => {
      expect(painted('あ\n# 日本語の見出し `コード`')).toEqual([
        ['#', DIM],
        ['日本語の見出し ', HEADING],
        ['`コード`', { ...HEADING, ...CODE }],
      ])
    })

    test('サロゲートペアを含む行でも範囲が本文と一致する', () => {
      expect(painted('𠮷😀\n- 𠮷😀 `😀`')).toEqual([
        ['-', LIST],
        ['`😀`', CODE],
      ])
    })

    test('末尾の改行の有無で結果が変わらない', () => {
      expect(painted('# a\n')).toEqual(painted('# a'))
    })
  })

  describe('上限', () => {
    const headingOf = (length: number) => `# ${'a'.repeat(length - 2)}`

    test('60,000文字ちょうどは色付けする', () => {
      expect(decorate(headingOf(MAX_CHARS))).not.toEqual([])
    })

    test('60,001文字は色付けしない', () => {
      expect(decorate(headingOf(MAX_CHARS + 1))).toEqual([])
    })
  })

  describe('U+2028・U+2029を含む長い行', () => {
    const MAX_REPEAT = MAX_CHARS - 2

    // 空白やマーカーの繰り返しの末尾にU+2028を置くと、正規表現が前段をバックトラックして二次時間になる
    test.each([' ', ' '])('末尾が%jの最悪ケースでも200ms以内に終わる', (separator) => {
      const worstCases = [
        `#${' '.repeat(MAX_REPEAT)}${separator}`,
        `>${' '.repeat(MAX_REPEAT)}${separator}`,
        `${'>'.repeat(MAX_REPEAT)}${separator}`,
        `${'> '.repeat(MAX_REPEAT / 2)}${separator}`,
      ]

      for (const text of worstCases) {
        const startedAt = performance.now()
        const result = decorate(text)

        expect(performance.now() - startedAt).toBeLessThan(200)
        expect(result).not.toEqual([])
        for (const { start, end } of result) {
          expect(end).toBeLessThanOrEqual(text.length)
          expect(end).toBeGreaterThan(start)
        }
      }
    })

    test.each([' ', ' '])('見出しの本文に%jを含んでも見出しとして装飾する', (separator) => {
      const [marker, body] = painted(`# a${separator}b`)

      expect(marker).toEqual(['#', DIM])
      expect(body[0]).toContain('a')
      expect(body[1]).toEqual(HEADING)
    })
  })

  describe('任意の入力', () => {
    const FRAGMENTS = [
      '```', '~~~', '`', '``', '# ', '#', '- ', '* ', '1. ', '> ', '>', '[ ] ', '[x] ', '---', '- - -',
      '\n', '\n', '\r\n', '\r', 'a', 'abc', '日本', '😀', '𠮷', ' ', '    ', '\t',
    ]

    const lcg = (seed: number) => () => {
      seed = (seed * 1664525 + 1013904223) % 2 ** 32

      return seed / 2 ** 32
    }

    const randomTexts = (count: number) => {
      const next = lcg(20260101)

      return Array.from({ length: count }, () =>
        Array.from({ length: Math.floor(next() * 40) }, () => FRAGMENTS[Math.floor(next() * FRAGMENTS.length)]).join(''),
      )
    }

    test('範囲は空でなくテキスト内に収まり、改行をまたがない', () => {
      for (const text of randomTexts(500)) {
        for (const { start, end } of decorate(text)) {
          expect(start).toBeGreaterThanOrEqual(0)
          expect(end).toBeLessThanOrEqual(text.length)
          expect(end).toBeGreaterThan(start)
          expect(text.slice(start, end)).not.toMatch(/[\r\n]/)
        }
      }
    })

    test('範囲は互いに重ならない', () => {
      for (const text of randomTexts(500)) {
        const ranges = decorate(text).sort((a, b) => a.start - b.start)

        ranges.slice(1).forEach(({ start }, i) => {
          expect(start).toBeGreaterThanOrEqual(ranges[i].end)
        })
      }
    })

    test('同じ入力には同じ結果を返す', () => {
      for (const text of randomTexts(100)) {
        expect(decorate(text)).toEqual(decorate(text))
      }
    })
  })

  describe('境界の組み合わせ', () => {
    test('番号付きリストのタスクも記号とチェックを別々に色付けする', () => {
      expect(painted('1. [x] a')).toEqual([
        ['1.', LIST],
        ['[x]', DONE],
      ])
    })

    test('本文のないタスクでもチェックを色付けする', () => {
      expect(painted('- [x]')).toEqual([
        ['-', LIST],
        ['[x]', DONE],
      ])
    })

    test('#の後ろがタブでも見出しになる', () => {
      expect(painted('#\ta')).toEqual([
        ['#', DIM],
        ['a', HEADING],
      ])
    })

    test('3スペースまでの字下げなら見出しになる', () => {
      expect(painted('   # a')).toEqual([
        ['#', DIM],
        ['a', HEADING],
      ])
    })

    test('見出しがインラインコードだけでもコード色になる', () => {
      expect(painted('# `a`')).toEqual([
        ['#', DIM],
        ['`a`', { ...HEADING, ...CODE }],
      ])
    })

    test('タブ字下げのリストでも記号がリスト色', () => {
      expect(painted('\t- a')).toEqual([['-', LIST]])
    })

    test('4スペース字下げの引用は引用ではない', () => {
      expect(painted('    > a')).toEqual([])
    })

    test('情報文字列にバッククォートを含む```はフェンスではない', () => {
      expect(painted('```a`b\nx')).toEqual([])
    })

    test('情報文字列にバッククォートを含む~~~はフェンスとして扱う', () => {
      expect(painted('~~~a`b\nx\n~~~')).toEqual([
        ['~~~a`b', DIM],
        ['x', CODE],
        ['~~~', DIM],
      ])
    })

    test('フェンスの閉じ行の末尾の空白は許す', () => {
      expect(painted('```\na\n```  \nb')).toEqual([
        ['```', DIM],
        ['a', CODE],
        ['```  ', DIM],
      ])
    })

    test('対にならない片割れのサロゲートがあっても範囲がずれない', () => {
      expect(painted('\uD800`a`')).toEqual([['`a`', CODE]])
    })
  })

  describe('最悪ケースの入力', () => {
    test.each([
      ['バッククォートだけの長い行', '`'.repeat(59_999) + 'a'],
      ['バッククォートが対にならない行', '`a'.repeat(30_000)],
      ['長さの違うバッククォートが並ぶ行', Array.from({ length: 340 }, (_, i) => '`'.repeat(i + 1) + 'x').join('')],
    ])('%sでも1秒以内に終わり、範囲は本文に収まる', (_name, text) => {
      const startedAt = performance.now()
      const result = decorate(text)

      expect(performance.now() - startedAt).toBeLessThan(1000)
      for (const { start, end } of result) {
        expect(start).toBeGreaterThanOrEqual(0)
        expect(end).toBeLessThanOrEqual(text.length)
        expect(end).toBeGreaterThan(start)
      }
    })
  })

  describe('4スペース字下げ', () => {
    test('コードとして扱わない', () => {
      expect(painted('text\n\n    code')).toEqual([])
    })
  })

  describe('コードフェンス', () => {
    test('フェンス行はdim、中身はコード色', () => {
      expect(painted('```ts\nconst a = 1\n```')).toEqual([
        ['```ts', DIM],
        ['const a = 1', CODE],
        ['```', DIM],
      ])
    })

    test('閉じる前でも末尾までコード色', () => {
      expect(painted('```\nlet a\nlet b')).toEqual([
        ['```', DIM],
        ['let a', CODE],
        ['let b', CODE],
      ])
    })

    test('フェンス内の記法は色付けしない', () => {
      expect(painted('```\n# a\n- b\n> c\n1. d\n---\n```')).toEqual([
        ['```', DIM],
        ['# a', CODE],
        ['- b', CODE],
        ['> c', CODE],
        ['1. d', CODE],
        ['---', CODE],
        ['```', DIM],
      ])
    })

    test('閉じた後は通常の記法に戻る', () => {
      expect(painted('```\na\n```\n# h')).toEqual([
        ['```', DIM],
        ['a', CODE],
        ['```', DIM],
        ['#', DIM],
        ['h', HEADING],
      ])
    })

    test('開きより短い閉じでは閉じない', () => {
      expect(painted('````\n```\n````')).toEqual([
        ['````', DIM],
        ['```', CODE],
        ['````', DIM],
      ])
    })

    test('種類の違うフェンスでは閉じない', () => {
      expect(painted('```\n~~~\n```')).toEqual([
        ['```', DIM],
        ['~~~', CODE],
        ['```', DIM],
      ])
    })

    test('言語名付きのフェンスでは閉じない', () => {
      expect(painted('```\n```ts\n```')).toEqual([
        ['```', DIM],
        ['```ts', CODE],
        ['```', DIM],
      ])
    })

    test('開きより長い閉じで閉じる', () => {
      expect(painted('```\na\n`````\nb')).toEqual([
        ['```', DIM],
        ['a', CODE],
        ['`````', DIM],
      ])
    })

    test('チルダでも開閉できる', () => {
      expect(painted('~~~\na\n~~~')).toEqual([
        ['~~~', DIM],
        ['a', CODE],
        ['~~~', DIM],
      ])
    })

    test.each([[' '], ['    '], ['\t']])('インデント%jのフェンスも認識する', (indent) => {
      expect(painted(`${indent}\`\`\`\n${indent}a\n${indent}\`\`\``)).toEqual([
        [`${indent}\`\`\``, DIM],
        [`${indent}a`, CODE],
        [`${indent}\`\`\``, DIM],
      ])
    })

    test('リスト項目内のフェンスも認識する', () => {
      const result = painted('- item\n  ```ts\n  a\n  ```')

      expect(result).toContainEqual(['  ```ts', DIM])
      expect(result).toContainEqual(['  a', CODE])
      expect(result).toContainEqual(['  ```', DIM])
    })

    test('引用内のフェンスは対象外', () => {
      expect(painted('> ```ts\n> a')).not.toContainEqual(['> ```ts', DIM])
    })

    test('同じ行で閉じるバッククォートはフェンスではない', () => {
      expect(painted('```a```\nb')).toEqual([['```a```', CODE]])
    })

    test('フェンス内の空行は装飾しない', () => {
      expect(painted('```\na\n\nb\n```')).toEqual([
        ['```', DIM],
        ['a', CODE],
        ['b', CODE],
        ['```', DIM],
      ])
    })
  })
})
