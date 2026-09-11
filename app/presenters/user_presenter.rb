class UserPresenter
    def initialize(user)
      @user = user
    end
  
    # 풀네임 가공
    def full_name
      "#{@user.last_name} #{@user.first_name}"
    end
  
    # 날짜 표시 포맷팅
    def formatted_created_at
      @user.created_at.strftime("%Y年%m月%d日")
    end
  end