// 通知のタップでアプリを開くための最小の Service Worker。
// キャッシュ(fetch の横取り)は一切しないので、画面の表示には影響しない。
self.addEventListener("install", () => self.skipWaiting())
self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()))

self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const path = event.notification.data?.path || "/routines"
  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((windows) => {
      for (const client of windows) {
        if ("focus" in client) {
          client.navigate?.(path)
          return client.focus()
        }
      }
      return self.clients.openWindow(path)
    })
  )
})
