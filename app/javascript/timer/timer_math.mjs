// タイマーの「時間の計算」だけを集めた純粋な関数(画面・localStorage・Date.now に依存しない)。
// 現在時刻 now(ms) は必ず引数で受け取る。単体テスト: test/js/timer_math.test.mjs
//
// 状態: { v, id, activityKey, label, anchor, totalMs, status, startedAt, startedAtIso, endAt,
//         remainingMs, lastSeenAt, finishedKind, actualMs, notifiedAt, submittingAt }
//   status: "running"(endAt を持つ) / "paused"(remainingMs を持つ) / "finished"
//   finishedKind: "complete"(最後まで) / "stopped"(「ここまででOK」)  actualMs: できた時間
export const STATE_VERSION = 1
export const MAX_AGE_MS = 23 * 60 * 60 * 1000       // これより古い状態は捨てる(サーバーの受付上限24時間より短く)
export const CLOCK_BACK_TOLERANCE_MS = 5000         // 時計の巻き戻しとみなす最小の差

export function start({ id, activityKey, label = "", anchor = "", totalMs, now }) {
  return {
    v: STATE_VERSION, id, activityKey, label, anchor, totalMs,
    status: "running", startedAt: now, startedAtIso: new Date(now).toISOString(),
    endAt: now + totalMs, remainingMs: null, lastSeenAt: now,
    finishedKind: null, actualMs: null, notifiedAt: null, submittingAt: null
  }
}

export function remainingMs(state, now) {
  if (state.status === "running") return Math.max(state.endAt - now, 0)
  if (state.status === "paused") return state.remainingMs
  return 0
}

export function elapsedMs(state, now) {
  if (state.status === "finished") return state.actualMs ?? state.totalMs
  return Math.min(Math.max(state.totalMs - remainingMs(state, now), 0), state.totalMs)
}

export function pause(state, now) {
  if (state.status !== "running") return state
  return { ...state, status: "paused", remainingMs: remainingMs(state, now), endAt: null, lastSeenAt: now }
}

export function resume(state, now) {
  if (state.status !== "paused") return state
  return { ...state, status: "running", endAt: now + state.remainingMs, remainingMs: null, lastSeenAt: now }
}

// 終了予定時刻を過ぎていたら finished にする。justFinished は「今回の呼び出しで終わりに変わった」
export function settle(state, now) {
  if (state.status === "running" && now >= state.endAt) {
    return { state: { ...state, status: "finished", finishedKind: "complete", actualMs: state.totalMs, remainingMs: 0 }, justFinished: true }
  }
  return { state, justFinished: false }
}

// 「ここまででOK」。1秒未満なら記録するものがないので null(破棄)
export function stop(state, now) {
  if (state.status === "finished") return state
  const done = elapsedMs(state, now)
  if (done < 1000) return null
  return { ...state, status: "finished", finishedKind: "stopped", actualMs: done, remainingMs: 0, endAt: null }
}

// 端末の時計が過去に戻された場合、進んだ分を失わないよう終了予定をずらす。進めた場合は区別できないのでそのまま
export function correctClock(state, now) {
  if (state.status !== "running") return state
  const back = state.lastSeenAt - now
  if (back > CLOCK_BACK_TOLERANCE_MS) {
    // 巻き戻した分(back)だけ、開始・終了予定も同じ向きにずらす → 観測済みの残り時間がそのまま保たれる
    return { ...state, startedAt: state.startedAt - back, endAt: state.endAt - back, lastSeenAt: now }
  }
  return state
}

export function actualSeconds(state) {
  return Math.max(Math.round((state.actualMs ?? state.totalMs) / 1000), 0)
}

// 保存された文字列から状態を復元する。壊れている・古すぎる場合は null。
// 既定(settle: true)では、running で終了時刻を過ぎていれば finished として返す(画面表示用)。
// settle: false なら running のまま返す。「今ちょうど終わった」を検知して通知するための読み方。
export function restore(raw, now, { settle: doSettle = true } = {}) {
  if (!raw) return null
  let data
  try { data = JSON.parse(raw) } catch { return null }
  if (!valid(data)) return null
  if (now - data.startedAt > MAX_AGE_MS) return null
  const corrected = correctClock(data, now)
  return doSettle ? settle(corrected, now).state : corrected
}

function valid(d) {
  const num = (v) => typeof v === "number" && Number.isFinite(v)
  if (!d || d.v !== STATE_VERSION || typeof d.activityKey !== "string" || !num(d.totalMs) || d.totalMs <= 0) return false
  if (!num(d.startedAt) || !num(d.lastSeenAt)) return false
  if (d.status === "running") return num(d.endAt)
  if (d.status === "paused") return num(d.remainingMs) && d.remainingMs >= 0
  if (d.status === "finished") return num(d.actualMs)
  return false
}
