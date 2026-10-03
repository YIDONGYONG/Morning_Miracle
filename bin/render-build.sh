#!/usr/bin/env bash
# Render のビルド手順（render.yaml の buildCommand から呼ばれる）。失敗したらそこで止める
set -o errexit

bundle install
yarn install
# JS(esbuild) と Tailwind をビルドしてから、アセットを public/assets にまとめる
bundle exec rails assets:precompile
# 新しいテーブル(routine_logs など)を本番 DB に反映する
bundle exec rails db:migrate
