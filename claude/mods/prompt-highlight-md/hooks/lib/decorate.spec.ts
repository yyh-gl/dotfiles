import { describe, expect, test } from 'bun:test'

import { decorate } from './decorate'
import { CODE_COLOR } from './palette'

const DIM = { dimColor: true }
const CODE = { color: CODE_COLOR }

const painted = (text: string) =>
  decorate(text).map(({ start, end, ...style }) => [text.slice(start, end), style])

describe('decorate', () => {
  test('空文字は装飾なし', () => {
    expect(decorate('')).toEqual([])
  })

  test('記法のない平文は装飾なし', () => {
    expect(decorate('hello world\nsecond line')).toEqual([])
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
