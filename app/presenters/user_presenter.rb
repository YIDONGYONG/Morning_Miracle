class UserPresenter
    def initialize(user)
      @user = user
    end
  
    # 姓名を整形して返す
    def full_name
      "#{@user.last_name} #{@user.first_name}"
    end
  
    # 登録日を表示用に整形して返す
    def formatted_created_at
      @user.created_at.strftime("%Y年%m月%d日")
    end
  end