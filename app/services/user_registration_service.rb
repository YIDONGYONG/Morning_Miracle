class UserRegistrationService
    def initialize(name:, email:, password:)
      @name = name
      @email = email
      @password = password
    end
  
    def call
      ActiveRecord::Base.transaction do
        user = User.create!(name: @name, email: @email, password: @password)
        UserMailer.welcome_email(user).deliver_later
        user
      end
    rescue ActiveRecord::RecordInvalid
      false
    end
  end