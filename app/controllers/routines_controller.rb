class RoutinesController < ApplicationController
  before_action :set_routine, only: %i[complete miss]

  # ルーティン一覧（未作成のカテゴリも取得して開始ボタンの表示に使う）
  def index
    @routines = current_user.routines.order(:category)
    @missing_categories = Routine.categories.keys - @routines.map(&:category)
  end

  # 4つのコアルーティンを Level 1 から一括で開始する
  def create
    Routine.categories.each_key do |category|
      current_user.routines.find_or_create_by!(category: category)
    end
    redirect_to routines_path, notice: "レベル1からスタートしました"
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

  # 自分のルーティンだけを取得する（他人のIDは404）
  def set_routine
    @routine = current_user.routines.find(params[:id])
  end

  # 今日の「達成」を記録する
  # 達成時のフラッシュメッセージ
  def complete_message(result)
    case result
    when :promoted then "おめでとう！ レベル#{@routine.current_level}に昇格しました"
    when :recorded then "達成を記録しました（連続 #{@routine.current_streak} 日）"
    else "今日はすでに記録済みです"
    end
  end

  # 今日の「未達成」を記録する
  # 未達成時のフラッシュメッセージ
  def miss_message(result)
    case result
    when :demoted then "レベル#{@routine.current_level}に戻りました。小さな一歩からやり直しましょう"
    when :recorded then "未達成を記録しました"
    else "今日はすでに記録済みです"
    end
  end
end
