import { Controller } from "@hotwired/stimulus"
import { timerStore } from "../timer/timer_store.js"

// サーバーに「今日は記録済み」と描かれたカードに付く。ブラウザに残っているそのルーティンの
// タイマーの状態(完了済みで送信待ち・途中のもの)を片付けて、ミニバッジなどを消す。
export default class extends Controller {
  static values = { activityKey: String }

  connect() {
    timerStore.clear(this.activityKeyValue)
  }
}
