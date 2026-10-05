class RoutinesController < ApplicationController
  before_action :set_routine, only: %i[complete miss]
  before_action :evaluate_last_week, only: :index

  # ルーティン一覧（未作成のカテゴリも取得して開始ボタンの表示に使う）
  def index
    @routines = current_user.routines.order(:category)
    @missing_categories = Routine.categories.keys - @routines.map(&:category)
    @today_logs = ActivityLog.where(user: current_user).completed_on(Date.current).index_by(&:activity_key)
  end

  # 4つのコアルーティンを Level 1 から一括で開始する
  def create
    Routine.categories.each_key do |category|
      current_user.routines.find_or_create_by!(category: category) { |routine| routine.current_level = current_user.level }
    end
    redirect_to routines_path, notice: "レベル1から始めました。小さな一歩で大丈夫です"
  end

  # 今日の「達成」を記録する
  def complete
    result = @routine.record_achieved!
    redirect_to routines_path, notice: complete_message(result)
  end

  # 今日の「未達成」を記録する
  def miss
    result = @routine.record_missed!
    redirect_to routines_path, notice: miss_message(result)
  end

  private

  # 接続したときに先週分を判定する（判定済みなら何もしない）
  def evaluate_last_week
    WeeklyEvaluator.new(current_user).call
  end

  # 自分のルーティンだけを取得する（他人のIDは404,1）
  def set_routine
    @routine = current_user.routines.find(params[:id])
  end

  # 達成時のフラッシュメッセージ
  def complete_message(result)
    result ? "今日の一歩、できましたね" : "今日はすでに記録済みです"
  end

  # 「今日は休む」時のフラッシュメッセージ（レベルは下がらない）
  def miss_message(result)
    result ? "今日はお休みですね。大丈夫、また明日" : "今日はすでに記録済みです"
  end
end
