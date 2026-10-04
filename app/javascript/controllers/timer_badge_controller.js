import { Controller } from "@hotwired/stimulus"
import * as M from "../timer/timer_math.mjs"
import { timerStore } from "../timer/timer_store.js"

// 進行中のタイマーを、ルーティン以外の画面でも小さく見せるミニバッジ。タップでルーティン画面(そのカード)へ。
// 状態は timerStore から読むだけ。終わる瞬間には settle() を呼び、完了通知(全タブで一度だけ)を出す。
export default class extends Controller {
  static targets = ["label", "time"]
  static values = { routinesPath: String }

  connect() {
    this.onVisibility = () => this.sync()
    document.addEventListener("visibilitychange", this.onVisibility)
    this.unsubscribe = timerStore.subscribe(() => this.sync())
    this.sync()
  }

  disconnect() {
    clearTimeout(this.timer)
    this.unsubscribe?.()
    document.removeEventListener("visibilitychange", this.onVisibility)
  }

  sync() {
    clearTimeout(this.timer)
    const { state } = timerStore.settle()
    // ルーティン画面では、カード自身がタイマーを見せるのでバッジは出さない
    if (!state || window.location.pathname.startsWith(this.routinesPathValue)) return this.hide()

    this.element.classList.remove("hidden")
    this.element.href = `${this.routinesPathValue}#${state.anchor}`
    this.labelTarget.textContent = state.label
    if (state.status === "finished") {
      this.timeTarget.textContent = "できました。記録する"
      return
    }
    const seconds = Math.max(Math.ceil(M.remainingMs(state, Date.now()) / 1000), 0)
    const clock = seconds < 60 ? `${seconds}秒` : `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`
    this.timeTarget.textContent = state.status === "paused" ? `${clock}（一時停止中）` : clock
    if (state.status === "running") this.timer = setTimeout(() => this.sync(), 1000)
  }

  hide() {
    this.element.classList.add("hidden")
  }
}
