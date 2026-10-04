import "@hotwired/turbo-rails"
import "./controllers"

// 完了通知のタップでアプリを開くための Service Worker(キャッシュはしない)
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker.js").catch(() => { /* 登録できなくても通常どおり使える */ })
}
