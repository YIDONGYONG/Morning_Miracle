// 実行: node --test test/js/   (外部ライブラリ不要)
import test from "node:test"
import assert from "node:assert/strict"
import * as M from "../../app/javascript/timer/timer_math.mjs"

const MIN = 60 * 1000
const T0 = 1_700_000_000_000
const base = () => M.start({ id: "a", activityKey: "exercise", label: "運動", anchor: "routine_1", totalMs: 10 * MIN, now: T0 })

test("start: endAt = startedAt + 10分、残り時間は endAt - now で毎回計算される", () => {
  const s = base()
  assert.equal(s.endAt, T0 + 10 * MIN)
  assert.equal(M.remainingMs(s, T0), 10 * MIN)
  assert.equal(M.remainingMs(s, T0 + 3 * MIN), 7 * MIN)   // 3分後に再起動 → 約7分
  assert.equal(M.remainingMs(s, T0 + 99 * MIN), 0)         // 負にならない
})

test("settle: 終了時刻を過ぎたら finished(complete)。ちょうど一度だけ justFinished", () => {
  const s = base()
  assert.equal(M.settle(s, T0 + 9 * MIN).justFinished, false)
  const r = M.settle(s, T0 + 10 * MIN)
  assert.equal(r.justFinished, true)
  assert.equal(r.state.status, "finished")
  assert.equal(r.state.finishedKind, "complete")
  assert.equal(M.actualSeconds(r.state), 600)
  assert.equal(M.settle(r.state, T0 + 11 * MIN).justFinished, false) // 二度目は通知しない
})

test("pause / resume: 残り時間が保たれ、停止中は進まない", () => {
  const paused = M.pause(base(), T0 + 4 * MIN)
  assert.equal(paused.status, "paused")
  assert.equal(M.remainingMs(paused, T0 + 4 * MIN), 6 * MIN)
  assert.equal(M.remainingMs(paused, T0 + 60 * MIN), 6 * MIN)    // 移動・終了しても変わらない
  const resumed = M.resume(paused, T0 + 20 * MIN)
  assert.equal(resumed.endAt, T0 + 26 * MIN)
  assert.equal(M.remainingMs(resumed, T0 + 21 * MIN), 5 * MIN)
})

test("pause / resume は状態が違えば何もしない(連打に強い)", () => {
  const s = base()
  assert.equal(M.resume(s, T0 + MIN), s)
  const p = M.pause(s, T0 + MIN)
  assert.equal(M.pause(p, T0 + 2 * MIN), p)
})

test("stop: できた分をそのまま認める。1秒未満は破棄", () => {
  const stopped = M.stop(base(), T0 + 3 * 1000)
  assert.equal(stopped.finishedKind, "stopped")
  assert.equal(M.actualSeconds(stopped), 3)
  assert.equal(M.stop(base(), T0 + 500), null)
  const afterPause = M.stop(M.pause(base(), T0 + 2 * MIN), T0 + 30 * MIN)
  assert.equal(M.actualSeconds(afterPause), 120)                 // 一時停止中の時間は数えない
})

test("restore: 実行中は続き、終了時刻を過ぎていれば finished、壊れていれば null", () => {
  const raw = JSON.stringify(base())
  assert.equal(M.restore(raw, T0 + 3 * MIN).status, "running")
  assert.equal(M.remainingMs(M.restore(raw, T0 + 3 * MIN), T0 + 3 * MIN), 7 * MIN)
  const done = M.restore(raw, T0 + 12 * MIN)
  assert.equal(done.status, "finished")
  assert.equal(M.actualSeconds(done), 600)
  assert.equal(M.restore("not json", T0), null)
  assert.equal(M.restore(null, T0), null)
  assert.equal(M.restore(JSON.stringify({ ...base(), v: 99 }), T0), null)
  assert.equal(M.restore(JSON.stringify({ ...base(), totalMs: "x" }), T0), null)
})

test("restore: 古すぎる状態は捨てる", () => {
  assert.equal(M.restore(JSON.stringify(base()), T0 + 24 * 60 * MIN), null)
})

test("restore: 一時停止中の状態はそのまま残り時間を保つ", () => {
  const raw = JSON.stringify(M.pause(base(), T0 + 4 * MIN))
  const s = M.restore(raw, T0 + 5 * 60 * MIN)
  assert.equal(s.status, "paused")
  assert.equal(M.remainingMs(s, T0 + 5 * 60 * MIN), 6 * MIN)
})

test("correctClock: 時計が過去に戻っても、進んだ分を失わない", () => {
  let s = { ...base(), lastSeenAt: T0 + 4 * MIN }                // 4分時点まで観測済み
  const back = M.correctClock(s, T0 + 4 * MIN - 60 * MIN)        // 時計が1時間戻された
  assert.equal(M.remainingMs(back, T0 + 4 * MIN - 60 * MIN), 6 * MIN)
  const small = M.correctClock(s, T0 + 4 * MIN - 2000)           // 2秒の揺らぎは無視
  assert.equal(small, s)
})

test("elapsedMs: 実行中・一時停止・完了で正しい", () => {
  assert.equal(M.elapsedMs(base(), T0 + 2 * MIN), 2 * MIN)
  assert.equal(M.elapsedMs(M.pause(base(), T0 + MIN), T0 + 9 * MIN), MIN)
  assert.equal(M.elapsedMs(M.stop(base(), T0 + 5 * MIN), T0 + 99 * MIN), 5 * MIN)
})

test("restore(settle:false): 終了時刻を過ぎた running をそのまま返す(終わる瞬間の検知・通知のため)", () => {
  const raw = JSON.stringify(base())
  const unsettled = M.restore(raw, T0 + 12 * MIN, { settle: false })
  assert.equal(unsettled.status, "running")
  const r = M.settle(unsettled, T0 + 12 * MIN)
  assert.equal(r.justFinished, true)              // 通知は、この一度だけ
  assert.equal(M.settle(r.state, T0 + 13 * MIN).justFinished, false)
})
