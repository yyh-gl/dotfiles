export type QuestionKind = 'dialog' | 'text'

export type QuestionItem = {
  question: string
  header: string
  multiSelect: boolean
  options: { label: string; description?: string; preview?: string }[]
}

export type Explanation = {
  status: 'idle' | 'loading' | 'done' | 'failed'
  text: string
  runId: number
}

export type Entry = {
  id: string
  kind: QuestionKind
  agentId?: string
  items: QuestionItem[]
  prompts: string[]
  lead: string
  state: 'pending' | 'answered' | 'cancelled'
  answers: Record<string, string>
  response?: string
  explanation: Explanation
}

export type PendingText = {
  question: string
  options: { label: string; description?: string }[]
  lead: string
  entryId?: string
}

declare module 'claude-code' {
  interface PluginState {
    'question-guide': {
      entries: Entry[]
      prompts: string[]
      isAiOn: boolean
      showHistory: boolean
      cursor: number
      waiting: PendingText | null
    }
  }
}
