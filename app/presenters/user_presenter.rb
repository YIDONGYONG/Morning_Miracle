class UserPresenter
    def initialize(user)
      @user = user
    end

    # 姓名を整形して返す
    def full_name
      "#{@user.last_name} #{@user.first_name}"
    end
end
