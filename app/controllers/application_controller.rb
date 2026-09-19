class ApplicationController < ActionController::Base
  helper_method :logged_in?, :current_user
  before_action :require_login

  def logged_in?
    !!current_user
  end

  def logout
    session[:user_id] = nil
    @current_user = nil
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  private

  def require_login
    redirect_to login_path unless logged_in?
  end
end
