import { Controller } from "@hotwired/stimulus"

// 円形リングタイマー。待機 → 進行中 → 完了(または「ここまででOK」で終了)。
// 経過時間は setInterval で1秒ずつ引かず、開始時刻との差で毎回計算する(タブが隠れてもずれない)。
// 描画は requestAnimationFrame、タブが隠れて止まる間は setTimeout と visibilitychange で補う。
// 完了・中断すると、フォーム(開始時刻 + できた秒数)を Turbo で送り、カードがサーバー側の表示に差し替わる。
const RADIUS = 54
const CIRCUMFERENCE = 2 * Math.PI * RADIUS

export default class extends Controller {
  static targets = ["face", "ring", "numbers", "remaining", "percent", "status",
                    "startButton", "pauseButton", "stopButton", "form", "startedAt", "actualSeconds", "soundToggle"]
  static values = { seconds: Number, pauseable: Boolean }

  connect() {
    this.state = "idle"            // idle / running / paused / finished
    this.elapsedBefore = 0         // 一時停止までに進んだ時間(ms)
    this.runStartedAt = null       // いまの再生を始めた時刻(ms)
    this.reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.ringTarget.style.strokeDasharray = CIRCUMFERENCE
    this.ringTarget.style.strokeDashoffset = CIRCUMFERENCE
    this.onVisibility = this.onVisibility.bind(this)
    document.addEventListener("visibilitychange", this.onVisibility)
  }

  // Turbo のページ移動でも、タイマー・アニメーション・画面ロックを必ず片付ける
  disconnect() {
    this.clearTimers()
    this.releaseWakeLock()
    document.removeEventListener("visibilitychange", this.onVisibility)
    if (this.audio) { this.audio.close?.(); this.audio = null }
  }

  // ---- 操作 ----
  start() {
    if (this.state !== "idle") return
    this.prepareAudio() // 音はユーザーのタップの中で準備する(ブラウザの自動再生制限のため)
    this.startedAtIso = new Date().toISOString()
    this.runStartedAt = Date.now()
    this.state = "running"
    this.startButtonTarget.classList.add("hidden")
    this.stopButtonTarget.classList.remove("hidden")
    if (this.hasPauseButtonTarget) this.pauseButtonTarget.classList.remove("hidden")
    this.announce("はじまりました")
    this.requestWakeLock()
    this.tick()
  }

  togglePause() {
    if (this.state === "running") {
      this.elapsedBefore = this.elapsedMs()
      this.runStartedAt = null
      this.state = "paused"
      this.clearTimers()
      this.releaseWakeLock()
      this.pauseButtonTarget.textContent = "つづける"
      this.render()
    } else if (this.state === "paused") {
      this.runStartedAt = Date.now()
      this.state = "running"
      this.pauseButtonTarget.textContent = "一時停止"
      this.requestWakeLock()
      this.tick()
    }
  }

  // 途中でやめても、できた分をそのまま認める
  stop() {
    if (this.state !== "running" && this.state !== "paused") return
    const elapsed = Math.min(Math.floor(this.elapsedMs() / 1000), this.secondsValue)
    this.clearTimers()
    this.releaseWakeLock()
    if (elapsed < 1) return this.reset() // 1秒未満は記録するものがないので、そっと待機に戻す
    this.state = "finished"
    this.hideButtons()
    this.render()
    this.announce(`${this.duration(elapsed)}もできました`)
    this.submit(elapsed)
  }

  // 「リングだけ見る」集中モード(数字を隠す)
  toggleFocus(event) {
    this.numbersTarget.classList.toggle("invisible", event.target.checked)
  }

  // ---- 時間の計算と描画 ----
  elapsedMs() {
    return this.elapsedBefore + (this.runStartedAt ? Date.now() - this.runStartedAt : 0)
  }

  tick() {
    this.clearTimers()
    if (this.state !== "running") return
    this.render()
    if (this.elapsedMs() >= this.secondsValue * 1000) return this.complete()
    this.schedule()
  }

  schedule() {
    const remainingMs = this.secondsValue * 1000 - this.elapsedMs()
    // 終了の瞬間に確実に呼ぶ(タブが隠れていても)
    this.endTimeout = setTimeout(() => this.tick(), remainingMs + 20)
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
    this.raf = this.timeout = this.endTimeout = null
  }

  render() {
    const total = this.secondsValue
    const fraction = Math.min(this.elapsedMs() / (total * 1000), 1)
    this.ringTarget.style.strokeDashoffset = CIRCUMFERENCE * (1 - fraction)
    const remaining = Math.max(Math.ceil(total - this.elapsedMs() / 1000), 0)
    this.remainingTarget.textContent = remaining < 60 ? String(remaining)
      : `${Math.floor(remaining / 60)}:${String(remaining % 60).padStart(2, "0")}`
    this.percentTarget.textContent = Math.floor(fraction * 100)
  }

  complete() {
    this.state = "finished"
    this.face().classList.add("ring-done") // リングがセージ色に変わる
    this.hideButtons()
    this.announce("できました")
    this.releaseWakeLock()
    this.notify()
    this.submit(this.secondsValue)
  }

  reset() {
    this.state = "idle"
    this.elapsedBefore = 0
    this.runStartedAt = null
    this.ringTarget.style.strokeDashoffset = CIRCUMFERENCE
    this.remainingTarget.textContent = this.secondsValue < 60 ? String(this.secondsValue)
      : `${Math.floor(this.secondsValue / 60)}:${String(this.secondsValue % 60).padStart(2, "0")}`
    this.percentTarget.textContent = "0"
    this.stopButtonTarget.classList.add("hidden")
    if (this.hasPauseButtonTarget) this.pauseButtonTarget.classList.add("hidden")
    this.startButtonTarget.classList.remove("hidden")
    this.statusTarget.textContent = ""
  }

  // ---- 送信(サーバーが開始時刻と経過時間を検証する) ----
  submit(actualSeconds) {
    this.startedAtTarget.value = this.startedAtIso
    this.actualSecondsTarget.value = actualSeconds
    this.formTarget.requestSubmit()
  }

  // ---- 補助 ----
  face() { return this.faceTarget }
  hideButtons() {
    this.startButtonTarget.classList.add("hidden")
    this.stopButtonTarget.classList.add("hidden")
    if (this.hasPauseButtonTarget) this.pauseButtonTarget.classList.add("hidden")
  }

  // 読み上げ(aria-live)は、はじまりと完了のときだけ
  announce(message) { this.statusTarget.textContent = message }

  duration(seconds) {
    const m = Math.floor(seconds / 60), s = seconds % 60
    if (m === 0) return `${s}秒`
    return s === 0 ? `${m}分` : `${m}分${s}秒`
  }

  // タブが隠れて戻ったとき、経過時間を時計から計算し直す
  onVisibility() {
    if (this.state !== "running") return
    if (!document.hidden) this.requestWakeLock()
    this.tick()
  }

  // 画面ロック(Screen Wake Lock)。未対応・失敗しても、タイマーは普通に動く
  async requestWakeLock() {
    try {
      if (!("wakeLock" in navigator) || this.wakeLock) return
      this.wakeLock = await navigator.wakeLock.request("screen")
      this.wakeLock.addEventListener("release", () => { this.wakeLock = null })
    } catch (_error) {
      this.wakeLock = null
    }
  }

  releaseWakeLock() {
    try { this.wakeLock?.release() } catch (_error) { /* 何もしない */ }
    this.wakeLock = null
  }

  // 完了のお知らせ: 振動(対応端末のみ)と、オンにしたときだけ小さな音
  notify() {
    try { navigator.vibrate?.([200, 100, 200]) } catch (_error) { /* 何もしない */ }
    this.beep()
  }

  prepareAudio() {
    if (!this.hasSoundToggleTarget || !this.soundToggleTarget.checked) return
    const Context = window.AudioContext || window.webkitAudioContext
    if (!Context) return
    this.audio = new Context()
    this.audio.resume?.()
  }

  beep() {
    if (!this.audio) return
    try {
      const osc = this.audio.createOscillator()
      const gain = this.audio.createGain()
      osc.type = "sine"
      osc.frequency.value = 523
      gain.gain.setValueAtTime(0.0001, this.audio.currentTime)
      gain.gain.exponentialRampToValueAtTime(0.15, this.audio.currentTime + 0.1)
      gain.gain.exponentialRampToValueAtTime(0.0001, this.audio.currentTime + 1.2)
      osc.connect(gain).connect(this.audio.destination)
      osc.start()
      osc.stop(this.audio.currentTime + 1.3)
    } catch (_error) { /* 音が出なくても完了には影響しない */ }
  }
}
