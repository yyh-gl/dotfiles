import { codeSpans } from './codeSpans'
import {
  CODE_COLOR,
  HEADING_COLOR,
  LIST_MARKER_COLOR,
  TASK_DONE_COLOR,
  TASK_TODO_COLOR,
  type Decoration,
} from './palette'

type Line = { start: number; text: string }
type Fence = { char: string; length: number }
type Style = Omit<Decoration, 'start' | 'end'>
type Body = { start: number; text: string; style: Style }
type Syntax = { marks: Decoration[]; body?: Body }

const FENCE_OPEN = /^\s*(`{3,}(?=[^`]*$)|~{3,})/
const FENCE_CLOSE = /^\s*(`{3,}|~{3,})\s*$/
const HEADING = /^( {0,3})(#{1,6})(?:([ \t]+)(.*))?$/
const RULE = /^ {0,3}([-*_])(?:[ \t]*\1){2,}[ \t]*$/
const LIST = /^([ \t]*)([-*+]|\d{1,9}[.)])(?=[ \t]|$)(?:([ \t]+)(\[[ xX]\])(?=[ \t]|$))?/
const QUOTE = /^( {0,3})((?:>[ \t]?)+)(.*)$/

const DIM: Style = { dimColor: true }
const CODE: Style = { color: CODE_COLOR }
const HEADING_TEXT: Style = { color: HEADING_COLOR, bold: true }
const LIST_MARKER: Style = { color: LIST_MARKER_COLOR }
const TASK_TODO: Style = { color: TASK_TODO_COLOR }
const TASK_DONE: Style = { color: TASK_DONE_COLOR }
const QUOTE_TEXT: Style = { italic: true }
const PLAIN: Style = {}

const splitLines = (text: string): Line[] => {
  const lines: Line[] = []
  let start = 0

  for (const lineText of text.split('\n')) {
    lines.push({ start, text: lineText })
    start += lineText.length + 1
  }

  return lines
}

const openingFence = (lineText: string): Fence | null => {
  const run = FENCE_OPEN.exec(lineText)?.[1]

  return run ? { char: run[0], length: run.length } : null
}

const closes = (fence: Fence, lineText: string) => {
  const run = FENCE_CLOSE.exec(lineText)?.[1]

  return run !== undefined && run[0] === fence.char && run.length >= fence.length
}

const span = (start: number, length: number, style: Style): Decoration[] =>
  length > 0 ? [{ start, end: start + length, ...style }] : []

const headingSyntax = ([, indent, marker, gap = '', body = '']: RegExpExecArray, lineStart: number): Syntax => {
  const markerStart = lineStart + indent.length

  return {
    marks: span(markerStart, marker.length, DIM),
    body: { start: markerStart + marker.length + gap.length, text: body, style: HEADING_TEXT },
  }
}

const listSyntax = ([matched, indent, marker, gap = '', task]: RegExpExecArray, line: Line): Syntax => {
  const markerStart = line.start + indent.length
  const taskStart = markerStart + marker.length + gap.length

  return {
    marks: [
      ...span(markerStart, marker.length, LIST_MARKER),
      ...(task ? span(taskStart, task.length, task === '[ ]' ? TASK_TODO : TASK_DONE) : []),
    ],
    body: { start: line.start + matched.length, text: line.text.slice(matched.length), style: PLAIN },
  }
}

const quoteSyntax = ([, indent, markers, body]: RegExpExecArray, lineStart: number): Syntax => {
  const markersStart = lineStart + indent.length

  return {
    marks: [...markers].flatMap((char, i) => (char === '>' ? span(markersStart + i, 1, DIM) : [])),
    body: { start: markersStart + markers.length, text: body, style: QUOTE_TEXT },
  }
}

const lineSyntax = (line: Line): Syntax => {
  const heading = HEADING.exec(line.text)

  if (heading) {
    return headingSyntax(heading, line.start)
  }

  if (RULE.test(line.text)) {
    return { marks: span(line.start, line.text.length, DIM) }
  }

  const list = LIST.exec(line.text)

  if (list) {
    return listSyntax(list, line)
  }

  const quote = QUOTE.exec(line.text)

  if (quote) {
    return quoteSyntax(quote, line.start)
  }

  return { marks: [], body: { start: line.start, text: line.text, style: PLAIN } }
}

const bodySyntax = ({ start, text, style }: Body): Decoration[] => {
  const decorations: Decoration[] = []
  const textRun = (from: number, to: number) => (style === PLAIN ? [] : span(start + from, to - from, style))
  let cursor = 0

  for (const code of codeSpans(text)) {
    decorations.push(...textRun(cursor, code.start))
    decorations.push(...span(start + code.start, code.end - code.start, { ...style, ...CODE }))
    cursor = code.end
  }

  return [...decorations, ...textRun(cursor, text.length)]
}

export const decorate = (text: string): Decoration[] => {
  const decorations: Decoration[] = []
  let fence: Fence | null = null

  for (const line of splitLines(text)) {
    if (fence) {
      const isClosing = closes(fence, line.text)

      decorations.push(...span(line.start, line.text.length, isClosing ? DIM : CODE))

      if (isClosing) {
        fence = null
      }
    } else if ((fence = openingFence(line.text))) {
      decorations.push(...span(line.start, line.text.length, DIM))
    } else {
      const { marks, body } = lineSyntax(line)

      decorations.push(...marks, ...(body ? bodySyntax(body) : []))
    }
  }

  return decorations
}
