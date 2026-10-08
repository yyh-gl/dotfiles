import { describe, expect, test } from 'bun:test'

import { decorate } from './decorate'
import {
  CODE_COLOR,
  HEADING_COLOR,
  LIST_MARKER_COLOR,
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
      expect(painted('```a```\nb')).toEqual([])
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
