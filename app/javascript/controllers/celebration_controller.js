import { Controller } from "@hotwired/stimulus"

// 全達成のお祝い演出を、数秒後(またはタップ)で静かに片付ける。
export default class extends Controller {
  static values = { delay: { type: Number, default: 4200 } }

  connect() {
    try { navigator.vibrate?.([60, 40, 60]) } catch (_error) { /* 振動できない端末では何もしない */ }
    this.timer = setTimeout(() => this.close(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  close() {
    this.element.remove()
  }
}
