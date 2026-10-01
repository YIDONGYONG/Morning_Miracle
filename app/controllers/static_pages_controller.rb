class StaticPagesController < ApplicationController
  skip_before_action :require_login, only: %i[top]
  # トップページ（ログイン不要）
  def top
 end
end
