import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Snap, Window } from '../types'

const snapAtom = atom({ plugin: 'statusline', key: 'snap' } as const, null)

const PRIMARY = '#769ff0'
const RED = 'red'
const GREEN = 'green'
const YELLOW = 'yellow'
const CYAN = 'cyan'

// 使用率に応じた色を返す（<70%緑 / 70-89%黄 / >=90%赤）
const rateColor = (percent: number) => {
  const v = Math.round(percent)

  return v >= 90 ? RED : v >= 70 ? YELLOW : GREEN
}

const pad2 = (n: number) => String(n).padStart(2, '0')

// ISO 8601 -> HH:MM
const fmtTime = (iso: string) => {
  const d = new Date(iso)

  return Number.isNaN(d.getTime()) ? '' : `${pad2(d.getHours())}:${pad2(d.getMinutes())}`
}

// ISO 8601 -> M/D HH:MM（先頭ゼロなし）
const fmtDateTime = (iso: string) => {
  const d = new Date(iso)

  return Number.isNaN(d.getTime()) ? '' : `${d.getMonth() + 1}/${d.getDate()} ${fmtTime(iso)}`
}

const basename = (path: string) => path.replace(/\/+$/, '').split('/').pop() ?? ''

const readBranch = async ($: EngineInterface) => {
  try {
    const { exitCode, stdout } = await $.process.run(['git', 'branch', '--show-current'])

    return exitCode === 0 ? stdout.trim() : ''
  } catch {
    return ''
  }
}

const findWindow = (
  windows: readonly { kind: string; percentUsed: number; resetsAt?: string }[],
  kind: string,
): Window | undefined => {
  const w = windows.find(x => x.kind === kind)

  return w && { percent: w.percentUsed, resetsAt: w.resetsAt }
}

// dir/branch/modelはモデル切替やcheckoutで変わるため、利用量の更新やターン完了のたびに取り直す
async function refresh($: EngineInterface) {
  const usage = await $.session.usage()
  const next: Snap = {
    dir: basename(await $.session.cwd()),
    branch: await readBranch($),
    model: await $.session.model(),
    ctx: usage.context.percent,
    five: findWindow(usage.rateLimits, 'five_hour'),
    seven: findWindow(usage.rateLimits, 'seven_day'),
    costUsd: usage.cost?.usd,
  }
  await update($, snapAtom, () => next)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await refresh($)

    return next(e)
  })

  on('session.measure', async ($, e, next) => {
    await refresh($)

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    await refresh($)

    return next(e)
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const snap = await read($, snapAtom)

    if (e.props.hasSurvey || snap === null) {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)

    const rate = (icon: string, label: string, w: Window | undefined, fmt: (iso: string) => string) => {
      if (!w) {
        return null
      }
      const reset = w.resetsAt ? fmt(w.resetsAt) : ''

      return (
        <Box>
          <Text>
            {icon}
            {label}{' '}
          </Text>
          <Text color={rateColor(w.percent)}>{Math.round(w.percent)}%</Text>
          {reset ? <Text dimColor> ↺{reset}</Text> : null}
        </Box>
      )
    }

    const line1 = [
      snap.dir ? (
        <Box key="dir">
          <Text>📁</Text>
          <Text color={PRIMARY}>{snap.dir}</Text>
        </Box>
      ) : null,
      snap.branch ? (
        <Text key="branch" color={YELLOW}>
          ⎇ {snap.branch}
        </Text>
      ) : null,
    ]

    const line2 = [
      <Box key="model">
        <Text>🤖</Text>
        <Text color={CYAN}>{snap.model}</Text>
      </Box>,
      snap.ctx === undefined ? null : (
        <Box key="ctx">
          <Text>📝</Text>
          <Text color={rateColor(snap.ctx)}>{Math.round(snap.ctx)}%</Text>
        </Box>
      ),
      rate('🕐', '5h', snap.five, fmtTime),
      rate('📅', '7d', snap.seven, fmtDateTime),
    ]

    const line3 = [
      snap.costUsd === undefined ? null : (
        <Box key="cost">
          <Text>💰${snap.costUsd.toFixed(2)} </Text>
          <Text dimColor>(session)</Text>
        </Box>
      ),
    ]

    // 空のセグメントを除いて「 | 」（dim）で連結する
    const joinRow = (key: string, segments: unknown[]) => {
      const present = segments.filter(Boolean)

      if (present.length === 0) {
        return null
      }

      return (
        <Box key={key}>
          {present.flatMap((seg, i) => [
            i > 0 ? (
              <Text key={`sep${i}`} dimColor>
                {' | '}
              </Text>
            ) : null,
            seg,
          ])}
        </Box>
      )
    }

    const rows = [joinRow('l1', line1), joinRow('l2', line2), joinRow('l3', line3)].filter(Boolean)

    return <Box flexDirection="column">{rows}</Box>
  })
}
