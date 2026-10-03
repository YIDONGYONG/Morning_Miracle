class StaticPagesController < ApplicationController
  skip_before_action :require_login, only: %i[top]

  # トップページ。ログイン中は「今日」のホーム、未ログインは紹介ページを表示する
  def top
    @home = HomePresenter.new(current_user, mood: params[:mood]) if logged_in?
  end
end
