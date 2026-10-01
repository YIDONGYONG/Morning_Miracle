# UI ガイド

スタイルは **Tailwind v4 のみ**。トークンと共通部品は `app/assets/tailwind/application.css` の 1 ファイルに集約している。
色コード(`#xxxxxx` / `rgb()`)をビューに書かない。必要な色がなければトークンを追加してから使う。

## トークン (`@theme`)
| 種類 | 名前 | 用途 |
|---|---|---|
| 面 | `canvas` / `card` / `surface-muted` / `line` | 背景 / カード / 二次ボタン / 区切り線 |
| 文字 | `ink` / `ink-body` / `ink-muted` / `ink-faint` | 見出し / 本文 / 補足 / 非活性 |
| ブランド | `brand` / `brand-2` / `brand-3` | 強調色とヘッダーのグラデーション |
| 状態 | `success` / `danger` / `danger-soft` | 成功 / 警告 |
| カテゴリ | `exercise` `meditation` `reading` `planning` (+`-soft`) | ルーティン別の色 |
| 形 | `rounded-card` / `rounded-hero` / `shadow-card` | 角丸・影 |

`bg-brand` `text-ink-muted` `rounded-card` `shadow-card` のように、そのままユーティリティとして使える。

## 共通部品 (`@layer components`)
| クラス | 役割 |
|---|---|
| `.page` / `.page-body` | ページ骨格。モバイルは下部タブ分の余白を確保 |
| `.hero` / `.cover` | 上部のグラデーションヘッダー / 画像ヘッダー(`shared/_hero`) |
| `.card` / `.card-grid` | カード / モバイル1列・PC2列のグリッド |
| `.btn` + `.btn-primary` `.btn-secondary` `.btn-danger` `.btn-tone` | ボタン(pill 型) |
| `.field-label` / `.field-input` / `.field-error` | フォーム |
| `.toast` + `.toast-success` `.toast-error` | フラッシュ(`shared/_flash_message`) |
| `.tabbar` / `.tab` / `.topnav-link` | モバイル下部タブ / PC上部ナビ |
| `.tone-*` + `.badge` `.icon-circle` `.meter` | ルーティンのカテゴリ色切り替え |

## 使用例
```erb
<div class="page">
  <%= render "shared/hero", title: "ビジョン作成" %>
  <main class="page-body max-w-md">
    <%= form_with model: @vision, class: "card space-y-4" do |f| %>
      <%= f.label :title, class: "field-label" %>
      <%= f.text_field :title, class: "field-input" %>
      <%= f.submit class: "btn btn-primary w-full" %>
    <% end %>
  </main>
</div>
```

## ルール
- モバイル(375px)を基準に書き、`md:` 以上で PC 向けに広げる。
- 新しい見た目が必要なら、まず既存の部品で足りないか確認し、足りなければ部品かトークンを追加する。
- 変更後は `bin/rails tailwindcss:build` で CSS を再生成する（開発中は `tailwindcss:watch`）。
