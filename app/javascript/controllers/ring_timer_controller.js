import { Controller } from "@hotwired/stimulus"
import * as M from "../timer/timer_math.mjs"
import { timerStore } from "../timer/timer_store.js"
import { ensurePermission } from "../timer/notifier.js"

// 円形リングタイマーの「見た目」担当。時間の状態そのものは timerStore(localStorage に保存)が持つので、
// 画面を移動しても、リロードしても、アプリを閉じて開き直しても、正しい残り時間から続きを描く。
// 経過時間は、開始時刻との差(endAt - 現在時刻)で毎回計算する。1秒ずつ引く方式は使わない。
// 描画は requestAnimationFrame、隠れたタブで止まる間は setTimeout と visibilitychange で補う。
// 終わった(または「ここまででOK」)ら、開始時刻と「できた秒数」を Turbo のフォームで送る。
const RADIUS = 54
const CIRCUMFERENCE = 2 * Math.PI * RADIUS
const WARN_BEFORE_SECONDS = (total) => (total >= 60 ? 10 : 3) // 終わる何秒前に知らせるか
const RETRY_SHOWN_AFTER_MS = 4000 // 送ったのにカードが差し替わらないとき、再送ボタンを出すまでの時間

export default class extends Controller {
  static targets = ["face", "ring", "remaining", "percent", "status", "startButton", "pauseButton", "stopButton",
                    "retryButton", "form", "startedAt", "actualSeconds"]
  static values = { seconds: Number, pauseable: Boolean, activityKey: String, label: String, anchor: String }

  connect() {
    this.warned = false
    this.model = null
    this.reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.ringTarget.style.strokeDasharray = CIRCUMFERENCE
    this.onVisibility = this.onVisibility.bind(this)
    document.addEventListener("visibilitychange", this.onVisibility)
    this.unsubscribe = timerStore.subscribe(() => this.sync())
    this.sync()
  }

  // Turbo のページ移動でも、リスナー・タイマー・アニメーション・画面ロックを必ず片付ける(状態そのものは残す)
  disconnect() {
    this.clearTimers()
    this.unsubscribe?.()
    this.releaseWakeLock()
    document.removeEventListener("visibilitychange", this.onVisibility)
    if (this.audio) { this.audio.close?.(); this.audio = null }
  }

  // ---- 操作 ----
  start() {
    ensurePermission() // 完了通知の許可は、ユーザーのタップの中で求める
    this.prepareAudio() // 音も、タップの中で準備する(ブラウザの自動再生制限のため)
    // 連打・複数タブでも、タイマーは1つだけ(すでにあれば作らず、いまの状態に合わせるだけ)
    const result = timerStore.start({
      activityKey: this.activityKeyValue, label: this.labelValue, anchor: this.anchorValue, totalMs: this.secondsValue * 1000
    })
    if (result.ok) this.announce("はじまりました")
    this.sync()
  }

  togglePause() {
    if (this.model?.status === "running") timerStore.pause()
    else if (this.model?.status === "paused") timerStore.resume()
    this.sync()
  }

  // 途中でやめても、できた分をそのまま認める
  stop() {
    if (!this.model || this.model.status === "finished") return
    const stopped = timerStore.stop()
    if (!stopped) { timerStore.clear(this.activityKeyValue); return this.sync() } // 1秒未満は記録せず待機に戻す
    this.announce(`${this.durationEn(M.actualSeconds(stopped))} counts. Nice start!`)
    this.sync()
  }

  // 送信に失敗したときの「もう一度送る」
  retry() {
    this.retryButtonTarget.classList.add("hidden")
    this.submitIfNeeded(true)
  }

  // ---- ストアの状態を画面に反映する ----
  sync() {
    const state = timerStore.current()
    const mine = state && state.activityKey === this.activityKeyValue ? state : null
    this.model = mine
    this.otherActive = Boolean(state && !mine) // 別のルーティンのタイマーが進行中

    if (!mine) return this.renderIdle()

    if (mine.status === "finished") return this.renderFinished()
    this.renderActive()
  }

  renderIdle() {
    this.clearTimers()
    this.releaseWakeLock()
    this.face().classList.remove("ring-done")
    this.ringTarget.style.strokeDashoffset = CIRCUMFERENCE
    this.setRemaining(this.secondsValue)
    this.percentTarget.textContent = "0"
    this.stopButtonTarget.classList.add("hidden")
    this.retryButtonTarget.classList.add("hidden")
    if (this.hasPauseButtonTarget) this.pauseButtonTarget.classList.add("hidden")
    this.startButtonTarget.classList.remove("hidden")
    // 別のタイマーが進行中なら、2つ目は始められない
    this.startButtonTarget.disabled = this.otherActive
    this.startButtonTarget.textContent = this.otherActive ? "別のタイマーが進行中です" : "はじめる"
    this.statusTarget.textContent = ""
  }

  renderActive() {
    const s = this.model
    this.face().classList.remove("ring-done")
    this.startButtonTarget.classList.add("hidden")
    this.stopButtonTarget.classList.remove("hidden")
    this.retryButtonTarget.classList.add("hidden")
    if (this.hasPauseButtonTarget) {
      this.pauseButtonTarget.classList.remove("hidden")
      this.pauseButtonTarget.textContent = s.status === "paused" ? "つづける" : "一時停止"
    }
    if (!this.warned && M.remainingMs(s, Date.now()) / 1000 <= WARN_BEFORE_SECONDS(this.secondsValue)) this.warned = true // 復元時は鳴らさない
    this.render()
    if (s.status === "running") {
      this.requestWakeLock()
      this.tick()
    } else {
      this.clearTimers()
      this.releaseWakeLock()
    }
  }

  renderFinished() {
    this.clearTimers()
    this.releaseWakeLock()
    const s = this.model
    this.hideButtons()
    this.render()
    if (s.finishedKind === "complete") {
      this.face().classList.add("ring-done") // リングがセージ色に変わる
      this.announce("Well done!")
    } else {
      this.announce(`${this.durationEn(M.actualSeconds(s))} counts. Nice start!`)
    }
    this.submitIfNeeded()
  }

  // ---- 時間の計算と描画 ----
  tick() {
    this.clearTimers()
    const { state, justFinished } = timerStore.settle()
    this.model = state && state.activityKey === this.activityKeyValue ? state : this.model
    if (justFinished) {
      this.notifyDevice([200, 100, 200], 1.2) // 振動と音(通知は timerStore が一度だけ出す)
      return this.sync()
    }
    if (!this.model || this.model.status !== "running") return this.sync()
    this.render()
    this.warnIfNeeded()
    this.schedule()
  }

  schedule() {
    const remainingMs = M.remainingMs(this.model, Date.now())
    // 終了の瞬間に確実に呼ぶ(タブが隠れていても)
    this.endTimeout = setTimeout(() => this.tick(), remainingMs + 20)
    if (!this.warned) {
      const untilWarn = remainingMs - WARN_BEFORE_SECONDS(this.secondsValue) * 1000
      this.warnTimeout = setTimeout(() => this.tick(), Math.max(untilWarn, 0) + 20)
    }
    if (this.reduceMotion) {
      this.timeout = setTimeout(() => this.tick(), 1000) // 動きを減らす設定: 1秒ごとに静かに更新
    } else {
      this.raf = requestAnimationFrame(() => this.tick())
      this.timeout = setTimeout(() => this.tick(), 500)  // rAF は隠れたタブで止まるため補助
    }
  }

  clearTimers() {
    cancelAnimationFrame(this.raf)
    clearTimeout(this.timeout)
    clearTimeout(this.endTimeout)
    clearTimeout(this.warnTimeout)
    clearTimeout(this.retryTimeout)
    this.raf = this.timeout = this.endTimeout = this.warnTimeout = this.retryTimeout = null
  }

  render() {
    const s = this.model
    const total = s.totalMs
    const now = Date.now()
    const elapsed = M.elapsedMs(s, now)
    const fraction = Math.min(elapsed / total, 1)
    this.ringTarget.style.strokeDashoffset = CIRCUMFERENCE * (1 - fraction)
    this.setRemaining(s.status === "finished" ? 0 : Math.max(Math.ceil(M.remainingMs(s, now) / 1000), 0))
    this.percentTarget.textContent = Math.floor(fraction * 100)
  }

  setRemaining(seconds) {
    this.remainingTarget.textContent = seconds < 60 ? String(seconds)
      : `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`
  }

  // ---- 送信(サーバーが開始時刻と経過時間を検証する) ----
  // 終わっていて、まだ送っていない(または他のタブが送っていない)ときだけ送る。失敗したら再送ボタンを出す
  submitIfNeeded(force = false) {
    const claimed = force ? this.claimForced() : timerStore.claimSubmit()
    if (!claimed) return this.scheduleRetryButton()
    this.startedAtTarget.value = claimed.startedAtIso
    this.actualSecondsTarget.value = M.actualSeconds(claimed)
    this.formTarget.requestSubmit()
    this.scheduleRetryButton()
  }

  claimForced() {
    const s = timerStore.current()
    if (!s || s.status !== "finished") return null
    return s
  }

  // 送信後も、このカードが差し替わらずに残っていたら(失敗した)、もう一度送れるようにする
  scheduleRetryButton() {
    clearTimeout(this.retryTimeout)
    this.retryTimeout = setTimeout(() => this.retryButtonTarget.classList.remove("hidden"), RETRY_SHOWN_AFTER_MS)
  }

  // ---- 補助 ----
  face() { return this.faceTarget }
  hideButtons() {
    this.startButtonTarget.classList.add("hidden")
    this.stopButtonTarget.classList.add("hidden")
    if (this.hasPauseButtonTarget) this.pauseButtonTarget.classList.add("hidden")
  }

  // 読み上げ(aria-live)は、はじまりと完了のときだけ(同じ文言のときは更新しない)
  announce(message) { if (this.statusTarget.textContent !== message) this.statusTarget.textContent = message }

  durationEn(seconds) {
    const m = Math.floor(seconds / 60), s = seconds % 60
    if (m === 0) return `${s} sec`
    return s === 0 ? `${m} min` : `${m} min ${s} sec`
  }

  // タブが隠れて戻ったとき、経過時間を時計から計算し直す
  onVisibility() {
    if (!this.model || this.model.status !== "running") return
    if (!document.hidden) this.requestWakeLock()
    this.tick()
  }

  // 終わる少し前に、一度だけそっと知らせる(短い音と軽い振動)
  warnIfNeeded() {
    if (this.warned) return
    const remaining = M.remainingMs(this.model, Date.now()) / 1000
    if (remaining > WARN_BEFORE_SECONDS(this.secondsValue)) return
    this.warned = true
    this.notifyDevice([80], 0.5)
  }

  // お知らせ: 振動(対応端末のみ)ややわらかい音。どちらも失敗しても進行には影響しない
  notifyDevice(vibration, soundSeconds) {
    try { navigator.vibrate?.(vibration) } catch (_error) { /* 何もしない */ }
    this.beep(soundSeconds)
  }

  // 画面ロック(Screen Wake Lock)。未対応・失敗しても、タイマーは普通に動く。取得中の二重呼び出しも防ぐ
  async requestWakeLock() {
    if (!("wakeLock" in navigator) || this.wakeLock || this.wakeLockPending) return
    this.wakeLockPending = true
    try {
      this.wakeLock = await navigator.wakeLock.request("screen")
      this.wakeLock.addEventListener("release", () => { this.wakeLock = null })
    } catch (_error) {
      this.wakeLock = null
    } finally {
      this.wakeLockPending = false
    }
  }

  releaseWakeLock() {
    try { this.wakeLock?.release() } catch (_error) { /* 何もしない */ }
    this.wakeLock = null
  }

  // AudioContext は使い回す(開始のたびに作ると、ブラウザの上限に近づく)
  prepareAudio() {
    const Context = window.AudioContext || window.webkitAudioContext
    if (!Context) return
    this.audio ||= new Context()
    this.audio.resume?.()
  }

  beep(seconds) {
    if (!this.audio) return
    try {
      const osc = this.audio.createOscillator()
      const gain = this.audio.createGain()
      osc.type = "sine"
      osc.frequency.value = 523
      gain.gain.setValueAtTime(0.0001, this.audio.currentTime)
      gain.gain.exponentialRampToValueAtTime(0.15, this.audio.currentTime + 0.1)
      gain.gain.exponentialRampToValueAtTime(0.0001, this.audio.currentTime + seconds)
      osc.connect(gain).connect(this.audio.destination)
      osc.start()
      osc.stop(this.audio.currentTime + seconds + 0.1)
    } catch (_error) { /* 音が出なくても完了には影響しない */ }
  }
}
