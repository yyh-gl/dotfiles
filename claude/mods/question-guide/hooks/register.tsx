// aieo-product/claude_qamods の qa-guide（MIT）の挙動を参考にした独自実装（コードはコピーしていない）
import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Entry, Explanation, PendingText, QuestionItem } from '../types'
import { appendEntry, appendPrompt, buildCompactContext, clampCursor, detectWaiting, entryAfterAnswer, isExplainTrigger, isUserOrigin, LEAD_TAIL_CHARS } from './lib'
import { paneView } from './pane'

const entriesAtom = atom({ plugin: 'question-guide', key: 'entries' } as const, [] as Entry[])
const promptsAtom = atom({ plugin: 'question-guide', key: 'prompts' } as const, [] as string[])
const isAiOnAtom = atom({ plugin: 'question-guide', key: 'isAiOn' } as const, true)
const showHistoryAtom = atom({ plugin: 'question-guide', key: 'showHistory' } as const, false)
const cursorAtom = atom({ plugin: 'question-guide', key: 'cursor' } as const, 0)
const waitingAtom = atom({ plugin: 'question-guide', key: 'waiting' } as const, null as PendingText | null)

const PANE_ID = 'question-guide'
const COMMAND = 'question-guide'
const ASK_TOOL = 'AskUserQuestion'

type AskOutput = { answers?: Record<string, string>; response?: string; afkTimeoutMs?: number }

const EXPLAIN_MODEL = 'haiku'
const EXPLAIN_MAX_TOKENS = 800
const EXPLAIN_TIMEOUT_MS = 30000
const MIN_COLUMNS = 10
const PROMPT_ANSWER_MAX_CHARS = 600
const TEXTLESS_ANSWER = '（テキストなしの入力）'

let sequence = 0

const newEntry = (
  kind: Entry['kind'],
  items: QuestionItem[],
  prompts: string[],
  lead: string,
  agentId?: string,
): Entry => ({
  id: `${Date.now()}-${sequence++}`,
  kind,
  agentId,
  items,
  prompts,
  lead: lead.slice(-LEAD_TAIL_CHARS),
  state: 'pending',
  answers: {},
  explanation: { status: 'idle', text: '', runId: 0 },
})

const messagesOf = async ($: EngineInterface, agentId?: string) => {
  if (agentId === undefined) {
    return $.session.messages()
  }
  const found = await $.session.messages({ agentId })

  return Array.isArray(found) ? found : []
}

const leadOf = async ($: EngineInterface, agentId?: string): Promise<string> =>
  (await messagesOf($, agentId)).findLast(m => m.role === 'assistant' && m.text !== '')?.text ?? ''

const openPane = async ($: EngineInterface, focus: boolean) => {
  try {
    const opened = await $.ui.open({ id: PANE_ID, title: '質問ガイド', ...(focus && { focus: true as const, closeOnEscape: true as const }) })

    if (!opened.isPlaced) {
      $.ui.toast('question-guide: 端末の幅が足りないためペインを開けません')
    }
  } catch {
    // ペインが開けなくても質問の処理は続ける
  }
}

const patchEntry = (
  $: EngineInterface,
  id: string,
  change: (entry: Entry) => Entry,
): Promise<Entry[]> => update($, entriesAtom, entries => entries.map(e => (e.id === id ? change(e) : e)))

const generate = async ($: EngineInterface, id: string, runId: number, signal: AbortSignal): Promise<Explanation> => {
  const failed: Explanation = { status: 'failed', text: '', runId }
  const entry = (await update($, entriesAtom, es => es)).find(e => e.id === id)
  if (entry === undefined) {
    return failed
  }

  try {
    const reply = await $.model.complete({
      model: EXPLAIN_MODEL,
      prompt: buildCompactContext({
        kind: entry.kind,
        messages: await messagesOf($, entry.agentId),
        prompts: entry.prompts,
        lead: entry.lead,
        questions: entry.items,
      }),
      maxTokens: EXPLAIN_MAX_TOKENS,
      timeoutMs: EXPLAIN_TIMEOUT_MS,
    }, { signal })

    return reply.isAnswered ? { status: 'done', text: reply.text.trim(), runId } : failed
  } catch {
    return failed
  }
}

const runs = new Map<string, AbortController>()

// 回答を待たせないよう呼び出し側はawaitしない。新しい依頼が来たら古い呼び出しを中断し、runIdが進んだ結果は捨てる
const explain = async ($: EngineInterface, id: string) => {
  let runId = 0
  await patchEntry($, id, e => {
    runId = e.explanation.runId + 1

    return { ...e, explanation: { status: 'loading', text: '', runId } }
  })
  if (runId === 0) {
    return
  }

  runs.get(id)?.abort()
  const run = new AbortController()
  runs.set(id, run)

  const result = await generate($, id, runId, run.signal)
  if (runs.get(id) === run) {
    runs.delete(id)
  }
  await patchEntry($, id, e => (e.explanation.runId === runId ? { ...e, explanation: result } : e))
}

const explainSafely = ($: EngineInterface, id: string) =>
  explain($, id).catch(() =>
    patchEntry($, id, e =>
      e.explanation.status === 'loading' ? { ...e, explanation: { ...e.explanation, status: 'failed' } } : e,
    ).catch(() => {}),
  )

const addEntry = async ($: EngineInterface, entry: Entry) => {
  const entries = await update($, entriesAtom, es => appendEntry(es, entry))
  await update($, cursorAtom, () => entries.length - 1)
  await update($, showHistoryAtom, () => false)
}

const explainIfEnabled = async ($: EngineInterface, id: string) => {
  if (await read($, isAiOnAtom)) {
    void explainSafely($, id)
  }
}

const asItems = (questions: readonly QuestionItem[]): QuestionItem[] =>
  questions.map(q => ({
    question: q.question,
    header: q.header,
    multiSelect: q.multiSelect,
    options: (q.options ?? []).map(o => ({ label: o.label, description: o.description, preview: o.preview })),
  }))

// 同じwaitingに対する依頼は最初の1回だけentryを作る。2回目以降は既存のentryを使い、新規かどうかを返す
const claimTextEntry = async ($: EngineInterface, waiting: PendingText): Promise<{ id: string; isNew: boolean }> => {
  const entry = newEntry(
    'text',
    [{ question: waiting.question, header: '', multiSelect: false, options: waiting.options }],
    await read($, promptsAtom),
    waiting.lead,
  )
  const claimed = await update($, waitingAtom, w => (w === null || w.entryId !== undefined ? w : { ...w, entryId: entry.id }))

  if (claimed === null || claimed.entryId !== entry.id) {
    return { id: claimed?.entryId ?? entry.id, isNew: false }
  }

  await addEntry($, entry)

  return { id: entry.id, isNew: true }
}

const explainWaiting = async ($: EngineInterface, waiting: PendingText): Promise<boolean> => {
  try {
    const { id, isNew } = await claimTextEntry($, waiting)
    await openPane($, false)
    if (isNew) {
      void explainSafely($, id)
    }

    return true
  } catch {
    return false
  }
}

// waitingを置き換える・閉じるときは、解説を依頼済みで回答待ちのままのentryを中断にする
const replaceWaiting = async ($: EngineInterface, next: PendingText | null) => {
  let replaced: PendingText | null = null
  await update($, waitingAtom, w => {
    replaced = w

    return next
  })
  const staleId = (replaced as PendingText | null)?.entryId
  if (staleId !== undefined) {
    await patchEntry($, staleId, it => (it.state === 'pending' ? { ...it, state: 'cancelled' } : it))
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: COMMAND, description: 'Claudeの質問の背景と選択肢の詳細を表示する' })

    return next(e)
  })

  on('command.run', { command: COMMAND }, async $ => {
    await openPane($, true)

    return { text: '質問ガイドを開きました' }
  })

  on('prompt.submit', async ($, e, next) => {
    if (!isUserOrigin(e.origin)) {
      return next(e)
    }

    const waiting = await read($, waitingAtom)

    if (isExplainTrigger(e.text)) {
      if (waiting === null) {
        return { drop: '解説できる質問がありません' }
      }

      return { drop: (await explainWaiting($, waiting)) ? '質問の解説をペインに表示します' : '質問の解説に失敗しました' }
    }

    const previousPrompts = await read($, promptsAtom)
    const isTextless = e.text.trim() === ''
    if (!isTextless) {
      await update($, promptsAtom, ps => appendPrompt(ps, e.text))
    }

    if (waiting?.entryId !== undefined) {
      await patchEntry($, waiting.entryId, it => ({
        ...it,
        state: 'answered',
        response: isTextless ? TEXTLESS_ANSWER : e.text.slice(0, PROMPT_ANSWER_MAX_CHARS),
      }))
    }
    if (waiting !== null) {
      await update($, waitingAtom, () => null)
    }

    const result = await next(e)

    if (result.drop !== undefined) {
      await update($, promptsAtom, () => previousPrompts)
      await update($, waitingAtom, () => waiting)
      if (waiting?.entryId !== undefined) {
        await patchEntry($, waiting.entryId, it => ({ ...it, state: 'pending', response: undefined }))
      }
    }

    return result
  }).catch(($, e, next) =>
    next.called ? next(e) : isUserOrigin(e.origin) && isExplainTrigger(e.text) ? { drop: '質問の解説に失敗しました' } : next(e),
  )

  on('turn.complete', async ($, e, next) => {
    if (e.agentId === undefined) {
      const detected = e.isAborted ? null : detectWaiting(e.answer)
      await replaceWaiting($, detected === null ? null : { ...detected, lead: e.answer.slice(-LEAD_TAIL_CHARS) })
    }

    return next(e)
  })

  on('tool.call', async ($, e, next) => {
    if (e.tool !== ASK_TOOL) {
      return next(e)
    }

    const entry = newEntry('dialog', asItems(e.questions), await read($, promptsAtom), await leadOf($, e.agentId), e.agentId)
    await addEntry($, entry)
    await openPane($, false)
    await explainIfEnabled($, entry.id)

    let result
    try {
      result = await next(e)
    } catch (error) {
      await patchEntry($, entry.id, it => ({ ...it, state: 'cancelled' })).catch(() => {})
      throw error
    }
    const answer = { deny: result.deny, isError: result.isError, output: (result.result ?? undefined) as AskOutput | undefined }

    await patchEntry($, entry.id, it => entryAfterAnswer(it, answer))

    return result
  })

  on('ui.render', { component: 'Pane', requestId: PANE_ID }, async ($, e) => {
    const entries = await read($, entriesAtom)

    return paneView(
      $.ui.resolve(e),
      {
        entries,
        cursor: await read($, cursorAtom),
        isAiOn: await read($, isAiOnAtom),
        showHistory: await read($, showHistoryAtom),
        columns: Math.max(e.props.bodyColumns, MIN_COLUMNS),
        bodyRows: Math.max(e.props.scroll.bodyRows, 1),
      },
      {
        moveTo: index => async () => {
          await update($, showHistoryAtom, () => false)
          await update($, cursorAtom, () => clampCursor(index, entries.length))
        },
        toggleHistory: () => update($, showHistoryAtom, v => !v),
        toggleAi: () => update($, isAiOnAtom, v => !v),
        explain: id => explainSafely($, id),
      },
    )
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const waiting = await read($, waitingAtom)
    const below = await next(e)

    if (waiting === null || e.props.hasSurvey || e.props.isWorking) {
      return below
    }

    const { Box, Text, Button } = $.ui.resolve(e)

    return (
      <Box flexDirection="column">
        {below}
        <Box>
          <Text color="yellow">質問を検出しました </Text>
          <Button
            key="explain"
            hotkey="y"
            onPress={async () => {
              const current = await read($, waitingAtom)
              if (current !== null) {
                await explainWaiting($, current)
              }
            }}
          >
            AI要約
          </Button>
          <Text dimColor>（?? + Enterでも可） </Text>
          <Button key="dismiss" role="dismiss" onPress={() => replaceWaiting($, null)}>
            ×
          </Button>
        </Box>
      </Box>
    )
  })
}
