# ルーティンを1回行った記録を保存し、Turbo Stream でカードと「迎えた朝」を差し替える（ページ全体は更新しない）
class ActivityLogsController < ApplicationController
  def create
    @routine = current_user.routines.find_by!(category: log_params[:activity_key])

    if @routine.recorded_today?
      @notice = "今日はすでに記録済みです"
      return render_streams
    end

    @log = ActivityLog.build_for(@routine, started_at: log_params[:started_at], actual_seconds: log_params[:actual_seconds])
    saved = ActivityLog.transaction do
      @log.save && (@result = @routine.record_achieved!(fully: @log.completed_fully)) || raise(ActiveRecord::Rollback)
    end

    if saved
      @notice = @log.message
      @fresh = true
      @all_cleared = current_user.cleared_all_today?
      render_streams
    else
      @notice = "うまく記録できませんでした。もう一度ためしてください"
      render_streams status: :unprocessable_content
    end
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
