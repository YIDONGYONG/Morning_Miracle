# ルーティンを1回行った記録を保存し、Turbo Stream でカードと「迎えた朝」を差し替える（ページ全体は更新しない）
class ActivityLogsController < ApplicationController
  def create
    @routine = current_user.routines.find_by!(category: log_params[:activity_key])
    status = :ok

    # 連打・同時リクエストでも1日1回しか記録されないよう、ルーティンの行をロックして確認から保存までを直列にする
    @routine.with_lock do
      if @routine.recorded_today?
        @notice = "今日はすでに記録済みです"
      else
        @log = ActivityLog.build_for(@routine, started_at: log_params[:started_at], actual_seconds: log_params[:actual_seconds])
        if @log.save
          @routine.record_achieved!(fully: @log.completed_fully)
          @notice = @log.message
          @fresh = true
        else
          @notice = "うまく記録できませんでした。もう一度ためしてください"
          status = :unprocessable_content
        end
      end
    end

    @all_cleared = @fresh && current_user.cleared_all_today?
    render_streams(status: status)
  end

  private

  def log_params
    params.require(:activity_log).permit(:activity_key, :started_at, :actual_seconds)
  end

  def render_streams(status: :ok)
    @today_logs = ActivityLog.where(user: current_user).completed_on(Date.current).index_by(&:activity_key)
    render :create, formats: :turbo_stream, status: status
  end
end
