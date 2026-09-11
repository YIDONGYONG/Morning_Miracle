class UserRegistrationForm
    include ActiveModel::Model
    include ActiveModel::Attributes
  
    # 폼에서 전달받을 필드 정의
    attribute :name, :string
    attribute :email, :string
    attribute :password, :string
  
    # 검증 규칙 (ActiveModel Validation)
    validates :name, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, presence: true, length: { minimum: 8 }
  
    def save
      return false unless valid?
  
      # 검증 통과 시 비즈니스 로직(Service) 호출
      UserRegistrationService.new(name:, email:, password:).call
    end
  end