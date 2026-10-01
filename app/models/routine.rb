class Routine < ApplicationRecord
  # 最大レベル
  MAX_LEVEL = 8
  PROMOTE_STREAK = 7   # 連続達成がこの日数に達したら昇格
  DEMOTE_MISSES = 3    # 連続未達成がこの日数に達したら降格

  belongs_to :user

  # カテゴリ（運動・瞑想・読書・1日の計画）

  enum :category, { exercise: 0, meditation: 1, reading: 2, planning: 3 }

  # 同じユーザーが同じカテゴリを重複して持てない
  validates :category, presence: true, uniqueness: { scope: :user_id }
  validates :current_level, inclusion: { in: 1..MAX_LEVEL }

  # 各レベルの目標 (index 0 = レベル1)
  LEVELS = [
    { concept: "スモールスタート（ハードルをゼロに）", exercise: "玄関の前に10秒立つ", meditation: "深呼吸 1回", reading: "本を 1ページ読む", planning: "今日やることを 1つ書き出す" },
    { concept: "行動開始（体を軽く起こす）", exercise: "軽い足踏み 1分", meditation: "瞑想 2分", reading: "読書 3分", planning: "メモ帳で今日の予定を確認する" },
    { concept: "習慣の固定（実行の定着）", exercise: "ストレッチ 3分", meditation: "瞑想 5分", reading: "読書 5分", planning: "今日やることを 2つ書き出す" },
    { concept: "時間拡張（初級フェーズ）", exercise: "ジョギング 5分", meditation: "瞑想 8分", reading: "読書 8分", planning: "簡単な優先順位をつける" },
    { concept: "リズム形成（中級フェーズ）", exercise: "ジョギング 8分", meditation: "瞑想 10分", reading: "読書 10分", planning: "主要なスケジュールの時間設定" },
    { concept: "没入誘導（上級フェーズ）", exercise: "ジョギング 10分", meditation: "瞑想 13分", reading: "読書 13分", planning: "一日のスケジュールの枠組みを作る" },
    { concept: "最終整備（完成へのステップ）", exercise: "ジョギング 12分", meditation: "瞑想 16分", reading: "読書 16分", planning: "詳細なタイムスケジュール配分" },
    { concept: "完成期（朝の1時間を支配完了）", exercise: "ジョギング 15分 (日光浴)", meditation: "瞑想 20分 (最高の状態)", reading: "読書 20分 (深い没入)", planning: "一日のスケジュール完成 (5分)" }
  ].freeze

  # カテゴリごとの一言説明（カード小見出し）
  CATEGORY_TAGLINES = { "exercise" => "からだを動かす", "meditation" => "心を整える", "reading" => "知識を広げる", "planning" => "一日を設計する" }.freeze

  # カテゴリの日本語表示名
  CATEGORY_LABELS = { "exercise" => "運動", "meditation" => "瞑想", "reading" => "読書", "planning" => "1日の計画" }.freeze

  # 表示用ヘルパー: 名前・説明・現在レベルの目標・コンセプト・最大/記録済み判定
  def category_label = CATEGORY_LABELS[category]
  def category_tagline = CATEGORY_TAGLINES[category]
  def level_data(level = current_level) = LEVELS[level - 1]
  def goal(level = current_level) = level_data(level)[category.to_sym]
  def concept = level_data[:concept]
  def max_level? = current_level >= MAX_LEVEL
  def recorded_today? = last_recorded_on == Date.current

  # 今日の達成を記録。ストリークが基準に達したら自動昇格。:promoted / :recorded / nil(記録済み)
  def record_achieved!
    return if recorded_today?

    self.current_streak += 1
    self.consecutive_misses = 0
    self.last_recorded_on = Date.current
    result = :recorded
    if current_streak >= PROMOTE_STREAK && !max_level?
      self.current_level += 1
      self.current_streak = 0
      result = :promoted
    end
    save!
    result
  end

  # 今日の未達成を記録。連続で基準に達したら自動降格。:demoted / :recorded / nil(記録済み)
  def record_missed!
    return if recorded_today?

    self.current_streak = 0
    self.consecutive_misses += 1
    self.last_recorded_on = Date.current
    result = :recorded
    if consecutive_misses >= DEMOTE_MISSES
      self.consecutive_misses = 0
      if current_level > 1
        self.current_level -= 1
        result = :demoted
      end
    end
    save!
    result
  end
end
