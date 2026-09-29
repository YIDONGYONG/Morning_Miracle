class Routine < ApplicationRecord
  # belongs_to :user
  # validates :title, presence: true
  # validates :category, presence: true
  belongs_to :user
end
    # self.data = [
    #   {
    #     id: 1,
    #     level: 1,
    #     concept: "スモールスタート（ハードルをゼロに）",
    #     exercise: "玄関の前に10秒立つ",
    #     meditation: "深呼吸 1回",
    #     reading: "本を 1ページ読む",
    #     planning: "今日やることを 1つ書き出す"
    #   },
    #   {
    #     id: 2,
    #     level: 2,
    #     concept: "行動開始（体を軽く起こす）",
    #     exercise: "軽い足踏み 1分",
    #     meditation: "瞑想 2分",
    #     reading: "読書 3分",
    #     planning: "メモ帳で今日の予定を確認する"
    #   },
    #   {
    #     id: 3,
    #     level: 3,
    #     concept: "習慣の固定（実行の定着）",
    #     exercise: "ストレッチ 3分",
    #     meditation: "瞑想 5分",
    #     reading: "読書 5分",
    #     planning: "今日やることを 2つ書き出す"
    #   },
    #   {
    #     id: 4,
    #     level: 4,
    #     concept: "時間拡張（初級フェーズ）",
    #     exercise: "ジョギング 5分",
    #     meditation: "瞑想 8分",
    #     reading: "読書 8分",
    #     planning: "簡単な優先順位をつける"
    #   },
    #   {
    #     id: 5,
    #     level: 5,
    #     concept: "リズム形成（中級フェーズ）",
    #     exercise: "ジョギング 8分",
    #     meditation: "瞑想 10分",
    #     reading: "読書 10分",
    #     planning: "主要なスケジュールの時間設定"
    #   },
    #   {
    #     id: 6,
    #     level: 6,
    #     concept: "没入誘導（上級フェーズ）",
    #     exercise: "ジョギング 10分",
    #     meditation: "瞑想 13分",
    #     reading: "読書 13分",
    #     planning: "一日のスケジュールの枠組みを作る"
    #   },
    #   {
    #     id: 7,
    #     level: 7,
    #     concept: "最終整備（完成へのステップ）",
    #     exercise: "ジョギング 12分",
    #     meditation: "瞑想 16分",
    #     reading: "読書 16分",
    #     planning: "詳細なタイムスケジュール配分"
    #   },
    #   {
    #     id: 8,
    #     level: 8,
    #     concept: "完成期（朝の1時間を支配完了）",
    #     exercise: "ジョギング 15分 (日光浴)",
    #     meditation: "瞑想 20分 (最高の状態)",
    #     reading: "読書 20分 (深い没入)",
    #     planning: "一日のスケジュール完成 (5分)"
    #   }
    # ]
  
    # # 4대 코어 루틴 목표를 Hash 형태로 한 번에 반환하는 헬퍼 메서드
    # def targets
    #   {
    #     exercise: exercise,
    #     meditation: meditation,
    #     reading: reading,
    #     planning: planning
    #   }
    # end

