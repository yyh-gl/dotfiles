import { CODE_COLOR, type Decoration } from './palette'

type Line = { start: number; text: string }
type Fence = { char: string; length: number }

const FENCE_OPEN = /^\s*(`{3,}(?=[^`]*$)|~{3,})/
const FENCE_CLOSE = /^\s*(`{3,}|~{3,})\s*$/

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

export const decorate = (text: string): Decoration[] => {
  const decorations: Decoration[] = []
  let fence: Fence | null = null

  for (const line of splitLines(text)) {
    const end = line.start + line.text.length

    if (fence) {
      if (closes(fence, line.text)) {
        decorations.push({ start: line.start, end, dimColor: true })
        fence = null
      } else if (line.text !== '') {
        decorations.push({ start: line.start, end, color: CODE_COLOR })
      }
    } else if ((fence = openingFence(line.text))) {
      decorations.push({ start: line.start, end, dimColor: true })
    }
  }

  return decorations
}
