export type CodeSpan = { start: number; end: number }

const backtickRunLength = (text: string, from: number) => {
  let end = from

  while (text[end] === '`') {
    end++
  }

  return end - from
}

const closingEnd = (text: string, from: number, length: number) => {
  let i = from

  while (i < text.length) {
    if (text[i] !== '`') {
      i++
      continue
    }

    const run = backtickRunLength(text, i)

    if (run === length) {
      return i + run
    }
    i += run
  }

  return -1
}

export const codeSpans = (text: string): CodeSpan[] => {
  const spans: CodeSpan[] = []
  let i = 0

  while (i < text.length) {
    if (text[i] !== '`') {
      i++
      continue
    }

    const length = backtickRunLength(text, i)
    const end = closingEnd(text, i + length, length)

    if (end === -1) {
      i += length
    } else {
      spans.push({ start: i, end })
      i = end
    }
  }

  return spans
}
