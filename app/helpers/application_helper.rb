module ApplicationHelper
  # ヘッダー表示用のユーザー名
  def current_user_name
    return unless current_user

    UserPresenter.new(current_user).full_name
  end

  # フラッシュの種類を、.toast のバリアント(CSSクラス)に変換する。未知の種類は成功扱い
  def flash_class(message_type)
    { "notice" => "toast-success", "alert" => "toast-error" }.fetch(message_type.to_s, "toast-success")
  end

  # 秒数を「10秒」「1分30秒」の形に整える（文言の組み立ては ActivityText に一本化）
  def format_duration(seconds)
    ActivityText.duration(seconds)
  end
end
