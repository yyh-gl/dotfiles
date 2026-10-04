export type Window = { percent: number; resetsAt?: string }

export type Snap = {
  dir: string
  branch: string
  model: string
  ctx?: number
  five?: Window
  seven?: Window
  costUsd?: number
}

declare module 'claude-code' {
  interface PluginState {
    statusline: { snap: Snap | null }
  }
}
