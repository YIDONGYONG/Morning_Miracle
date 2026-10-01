import { Controller } from "@hotwired/stimulus"

// フラッシュメッセージを一定時間後に自動で消す。
// 画面を覆い続けないよう、メッセージは通知として短時間だけ表示する。
export default class extends Controller {
  static values = { delay: { type: Number, default: 4000 } }

  connect() {
    this.timer = setTimeout(() => this.element.remove(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
