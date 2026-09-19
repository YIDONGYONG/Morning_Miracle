module ApplicationHelper
  def current_user_name
    return unless current_user

    UserPresenter.new(current_user).full_name
  end

  def flash_class(message_type)
    {
      notice: "success",
      alert: "danger"
    }.fetch(message_type.to_sym, message_type)
  end
end
