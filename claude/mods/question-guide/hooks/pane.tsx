/** @jsxRuntime classic */
/** @jsx h */
/** @jsxFrag Fragment */
import type { EngineInterface } from 'claude-code'

import type { Entry, QuestionItem } from '../types'
import { answeredLabels, clampCursor, customAnswers, oneLine, promptLines, stringWidth, truncateCells, wrappedLines } from './lib'

const EMPTY_MESSAGE = 'まだ質問はありません。Claudeが質問するとここに背景と選択肢が表示されます。'
const PREVIEW_MAX_LINES = 6
const COMPACT_PROMPTS = 3
const DETAIL_LEAD_ROWS = 12
const COMPACT_HEADINGS = 4
const EXPLANATION_SHARE = 0.6
const EXPLAIN_FAILED = '生成できませんでした'

type Resolved = ReturnType<EngineInterface['ui']['resolve']>
type Ui = Pick<Resolved, 'Box' | 'Text' | 'Button'>

export type PaneModel = {
  entries: Entry[]
  cursor: number
  isAiOn: boolean
  showHistory: boolean
  columns: number
  bodyRows: number
}

export type PaneActions = {
  moveTo: (index: number) => () => void | Promise<unknown>
  toggleHistory: () => void | Promise<unknown>
  toggleAi: () => void | Promise<unknown>
  explain: (id: string) => void | Promise<unknown>
}

const stateLabel = (entry: Entry): string =>
  entry.state === 'pending' ? '回答待ち' : entry.state === 'cancelled' ? '中断' : '回答済み'

type View = {
  ui: Ui
  model: PaneModel
  actions: PaneActions
  cursor: number
  entry: Entry
}

type ControlSpec = { hotkey: string; label: string; onPress: () => void | Promise<unknown> }

const controlSpecs = ({ model, actions, cursor, entry }: View): ControlSpec[] => [
  { hotkey: 'p', label: '前へ', onPress: actions.moveTo(cursor - 1) },
  { hotkey: 'n', label: '次へ', onPress: actions.moveTo(cursor + 1) },
  { hotkey: 'l', label: '最新', onPress: actions.moveTo(model.entries.length - 1) },
  { hotkey: 'h', label: '一覧', onPress: actions.toggleHistory },
  { hotkey: 'a', label: `AI解説:${model.isAiOn ? 'ON' : 'OFF'}`, onPress: actions.toggleAi },
  { hotkey: 'e', label: '解説を生成', onPress: () => actions.explain(entry.id) },
]

const controlsRows = (view: View): number =>
  Math.ceil(stringWidth(controlSpecs(view).map(c => `${c.hotkey}: ${c.label}`).join(' ')) / view.model.columns)

const textLines = ({ ui, model }: View, prefix: string, text: string, props: Record<string, unknown> = {}) =>
  wrappedLines(text, model.columns).map((line, i) => (
    <ui.Text key={`${prefix}${i}`} {...props}>
      {line}
    </ui.Text>
  ))

const controlsOf = (view: View) => {
  const { Box, Text, Button } = view.ui

  return (
    <Box key="controls">
      {controlSpecs(view).map(({ hotkey, label, onPress }, i) => (
        <Box key={hotkey}>
          {i > 0 ? <Text> </Text> : null}
          <Button hotkey={hotkey} plain onPress={onPress}>{label}</Button>
        </Box>
      ))}
    </Box>
  )
}

const titleOf = ({ ui: { Text }, model, cursor, entry }: View) => (
  <Text key="title" bold>
    {`質問 ${cursor + 1}/${model.entries.length}（${stateLabel(entry)}）`}
  </Text>
)

function historyView(view: View) {
  const { Box, Text } = view.ui
  const { entries, columns } = view.model

  return (
    <Box flexDirection="column">
      <Text bold>質問の履歴（{entries.length}件）</Text>
      {entries.map((it, i) => (
        <Text key={it.id} color={i === view.cursor ? 'cyan' : undefined}>
          {truncateCells(
            `${i === view.cursor ? '▶' : ' '} ${i + 1}. [${stateLabel(it)}] ${oneLine(it.items[0]?.header || it.items[0]?.question || '')}`,
            columns,
          )}
        </Text>
      ))}
      {controlsOf(view)}
    </Box>
  )
}

const recentPromptLines = ({ ui: { Text }, model, entry }: View) =>
  entry.prompts
    .slice(-COMPACT_PROMPTS)
    .flatMap((p, i) => promptLines(p, model.columns).map((line, j) => <Text key={`r${i}-${j}`}>{line}</Text>))

function compactView(view: View) {
  const { Box, Text } = view.ui
  const { columns, bodyRows } = view.model
  const available = Math.max(bodyRows - COMPACT_HEADINGS - controlsRows(view), 0)
  const recent = recentPromptLines(view).slice(0, Math.ceil(available / 2))
  const free = available - recent.length
  const explanation = explanationLines(view).slice(0, Math.floor(free * EXPLANATION_SHARE))
  const leadRows = free - explanation.length

  return (
    <Box flexDirection="column">
      {titleOf(view)}
      <Text color="yellow">最近の指示</Text>
      {recent}
      <Text color="yellow">AI解説</Text>
      {explanation}
      <Text color="yellow">直前の説明</Text>
      {leadRows > 0 ? textLines(view, 'l', view.entry.lead).slice(-leadRows) : null}
      {controlsOf(view)}
    </Box>
  )
}

function itemView(view: View, item: QuestionItem, qi: number) {
  const { Box, Text } = view.ui
  const chosen = answeredLabels(item, view.entry)
  const custom = customAnswers(item, view.entry).join(' / ')

  return (
    <Box key={`q${qi}`} flexDirection="column">
      <Text color="cyan">{item.header ? `【${item.header}】` : '質問'}</Text>
      {textLines(view, `q${qi}-`, item.question, { bold: true })}
      {item.options.map((o, oi) => (
        <Box key={`o${oi}`} flexDirection="column">
          <Text color={chosen.has(o.label) ? 'green' : undefined}>{`${chosen.has(o.label) ? '✔' : '・'} ${o.label}`}</Text>
          {o.description ? textLines(view, `d${qi}-${oi}-`, `   ${o.description}`, { dimColor: true }) : null}
          {o.preview ? textLines(view, `p${qi}-${oi}-`, o.preview, { dimColor: true }).slice(0, PREVIEW_MAX_LINES) : null}
        </Box>
      ))}
      {custom ? textLines(view, `f${qi}-`, `✔ 自由記述: ${custom}`, { color: 'green' }) : null}
    </Box>
  )
}

function explanationLines(view: View) {
  const { explanation, kind } = view.entry

  switch (explanation.status) {
    case 'loading':
      return textLines(view, 'x', '解説を生成中…', { dimColor: true })
    case 'failed':
      return textLines(view, 'x', EXPLAIN_FAILED, { color: 'red' })
    case 'done':
      return textLines(view, 'x', explanation.text)
    default:
      return view.model.isAiOn && kind === 'dialog' ? [] : textLines(view, 'x', 'eキーで解説を生成します。', { dimColor: true })
  }
}

function detailView(view: View) {
  const { Box, Text } = view.ui

  return (
    <Box flexDirection="column">
      {titleOf(view)}
      {view.entry.items.map((item, qi) => itemView(view, item, qi))}
      {view.entry.response ? textLines(view, 'resp', `✔ 自由記述: ${view.entry.response}`, { color: 'green' }) : null}
      <Text color="yellow">AI解説</Text>
      {explanationLines(view)}
      <Text color="yellow">最近の指示</Text>
      {recentPromptLines(view)}
      <Text color="yellow">直前の説明</Text>
      {textLines(view, 'l', view.entry.lead).slice(-DETAIL_LEAD_ROWS)}
      {controlsOf(view)}
    </Box>
  )
}

export function paneView(ui: Ui, model: PaneModel, actions: PaneActions) {
  const { Box, Text } = ui

  if (model.entries.length === 0) {
    return (
      <Box flexDirection="column">
        <Text dimColor>{EMPTY_MESSAGE}</Text>
      </Box>
    )
  }

  const cursor = clampCursor(model.cursor, model.entries.length)
  const view: View = { ui, model, actions, cursor, entry: model.entries[cursor] as Entry }

  if (model.showHistory) {
    return historyView(view)
  }

  return view.entry.state === 'pending' && view.entry.kind === 'dialog' ? compactView(view) : detailView(view)
}
