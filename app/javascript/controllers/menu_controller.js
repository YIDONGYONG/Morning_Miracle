import { Controller } from "@hotwired/stimulus"

// 「⋯」ボタンで開閉するメニュー。外側のクリックや Esc キーで閉じる。
export default class extends Controller {
  static targets = ["panel", "button"]

  toggle() {
    this.panelTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.panelTarget.hidden = false
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.panelTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  closeOnOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  closeOnEscape() {
    this.close()
  }
}
