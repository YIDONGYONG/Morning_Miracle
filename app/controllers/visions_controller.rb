class VisionsController < ApplicationController
  before_action :set_vision, only: [:show, :edit, :update, :destroy]
  # before_action :set_vision, only: [ :destroy ]
  # skip_before_action :require_login, only: [ :index, :create, :destroy ] # 필요에 따라 권한 설정

  # 1. READ (목록)
  def index
    @visions = Vision.all
  end

  # 2. READ (상세)
  def show
    @vision = Vision.find(params[:id])
  end

  # 3. CREATE (작성 폼)
  def new
    @vision = Vision.new
  end

  # 3. CREATE (DB 저장)
  def create
    @vision = current_user.visions.build(vision_params)

    if @vision.save
      redirect_to @vision, notice: '비전이 성공적으로 등록되었습니다.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # 4. UPDATE (수정 폼)
  def edit
    @vision = current_user.visions.find(params[:id])
  end

  # 4. UPDATE (DB 수정)
  def update
    if @vision.update(vision_params)
      redirect_to @vision, notice: '비전이 성공적으로 수정되었습니다.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 5. DELETE (삭제)
  def destroy
    @vision.destroy
    redirect_to visions_path, status: :see_other, notice: '비전이 삭제되었습니다.'
  end

  private

  # 반복되는 단일 데이터 조회를 위한 콜백
  def set_vision
    @vision = Vision.find(params[:id])
  end

  def vision_params
    params.require(:vision).permit(:title, :content)
  end

end