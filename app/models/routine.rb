class Routine < ApplicationRecord
  # 最大レベル
  MAX_LEVEL = 8
  # 開発・検証用: 環境変数 DEBUG_TIMER_SECONDS=10 のように指定すると、全タイマーをその秒数にできる(本番では無視)
  DEBUG_TIMER_SECONDS = (ENV["DEBUG_TIMER_SECONDS"].to_i if ENV["DEBUG_TIMER_SECONDS"].present? && !Rails.env.production?)

  # レベルの上げ下げはここでは行わない（週ごとの判定: WeeklyEvaluator と User#change_level!）

  belongs_to :user
  has_many :logs, class_name: "RoutineLog", dependent: :destroy

  # カテゴリ（運動・瞑想・読書・1日の計画）

  enum :category, { exercise: 0, meditation: 1, reading: 2, planning: 3 }

  # 同じユーザーが同じカテゴリを重複して持てない
  validates :category, presence: true, uniqueness: { scope: :user_id }
  validates :current_level, inclusion: { in: 1..MAX_LEVEL }

  # 活動の定義。kind は :timer(時間を測る) / :count(回数・分量) / :check(行動の確認)
  #   label は表示文のもと。%{value} があれば値(10秒・1ページ など)をその位置に入れる(ActivityText 参照)
  def self.timer(label, seconds, note: nil) = { label: label, kind: :timer, seconds: seconds, note: note }.compact
  def self.count(label, amount, unit) = { label: label, kind: :count, amount: amount, unit: unit }
  def self.check(label, amount: nil, unit: nil) = { label: label, kind: :check, amount: amount, unit: unit }.compact
  private_class_method :timer, :count, :check

  # 各レベルの目標 (index 0 = レベル1)
  LEVELS = [
    { concept: "スモールスタート（ハードルをゼロに）",
      exercise: timer("玄関の前に%{value}立つ", 10), meditation: count("深呼吸", 1, "回"),
      reading: count("本を %{value}読む", 1, "ページ"), planning: check("今日やることを %{value}書き出す", amount: 1, unit: "つ") },
    { concept: "行動開始（体を軽く起こす）",
      exercise: timer("軽い足踏み", 60), meditation: timer("瞑想", 120),
      reading: timer("読書", 180), planning: check("メモ帳で今日の予定を確認する") },
    { concept: "習慣の固定（実行の定着）",
      exercise: timer("ストレッチ", 180), meditation: timer("瞑想", 300),
      reading: timer("読書", 300), planning: check("今日やることを %{value}書き出す", amount: 2, unit: "つ") },
    { concept: "時間拡張（初級フェーズ）",
      exercise: timer("ジョギング", 300), meditation: timer("瞑想", 480),
      reading: timer("読書", 480), planning: check("簡単な優先順位をつける") },
    { concept: "リズム形成（中級フェーズ）",
      exercise: timer("ジョギング", 480), meditation: timer("瞑想", 600),
      reading: timer("読書", 600), planning: check("主要なスケジュールの時間設定") },
    { concept: "没入誘導（上級フェーズ）",
      exercise: timer("ジョギング", 600), meditation: timer("瞑想", 780),
      reading: timer("読書", 780), planning: check("一日のスケジュールの枠組みを作る") },
    { concept: "最終整備（完成へのステップ）",
      exercise: timer("ジョギング", 720), meditation: timer("瞑想", 960),
      reading: timer("読書", 960), planning: check("詳細なタイムスケジュール配分") },
    { concept: "完成期（朝の1時間を支配完了）",
      exercise: timer("ジョギング", 900, note: "日光浴"), meditation: timer("瞑想", 1200, note: "最高の状態"),
      reading: timer("読書", 1200, note: "深い没入"), planning: timer("一日のスケジュール完成 (%{value})", 300) }
  ].freeze

  # カテゴリごとの一言説明（カード小見出し）
  CATEGORY_TAGLINES = { "exercise" => "からだを動かす", "meditation" => "心を整える", "reading" => "知識を広げる", "planning" => "一日を設計する" }.freeze

  # カテゴリの日本語表示名
  CATEGORY_LABELS = { "exercise" => "運動", "meditation" => "瞑想", "reading" => "読書", "planning" => "1日の計画" }.freeze

  # 表示用ヘルパー: 名前・説明・現在レベルの目標・コンセプト・最大/記録済み判定
  def category_label = CATEGORY_LABELS[category]
  def category_tagline = CATEGORY_TAGLINES[category]
  def level_data(level = current_level) = LEVELS[level - 1]
  def activity(level = current_level) = level_data(level)[category.to_sym]
  def goal(level = current_level) = ActivityText.text(activity(level))
  def concept = level_data[:concept]
  # タイマーの実際の長さ(秒)。サーバーの検証(ActivityLog)と画面の両方がこの値を使う
  def timer_seconds = DEBUG_TIMER_SECONDS || activity[:seconds]
  def max_level? = current_level >= MAX_LEVEL
  def recorded_today? = last_recorded_on == Date.current

  # 今日の達成を記録する。fully=false は「途中でやめた」(できた分は認めるが、週のクリア日には数えない)。:recorded / nil(記録済み)
  def record_achieved!(fully: true)
    return if recorded_today?

    update!(last_recorded_on: Date.current)
    write_log!(true, fully: fully)
    :recorded
  end

  # 「今日は休む」を記録する。レベルは下がらない。:recorded / nil(記録済み)
  def record_missed!
    return if recorded_today?

    update!(last_recorded_on: Date.current)
    write_log!(false, fully: false)
    :recorded
  end

  private

  # 今日の記録を1件だけ保存する（同じ日に再記録されても重複させない）
  def write_log!(achieved, fully:)
    logs.find_or_initialize_by(recorded_on: Date.current).update!(achieved: achieved, completed_fully: fully)
  end
end
