class VisionsController < ApplicationController
  before_action :set_vision, only: [ :destroy ]
  skip_before_action :require_login, only: [ :index, :create, :destroy ] # 필요에 따라 권한 설정

  # 1. 대시보드 목록 조회 및 생성 폼 준비 🖼️
  def index
    @visions = Vision.all.order(created_at: :desc)
    @vision = Vision.new
  end

  # 2. 타이틀 등록 ➕
  def create
    @vision = Vision.new(vision_params)
    if @vision.save
      redirect_to visions_path, notice: "비전이 등록되었습니다!"
    else
      @visions = Vision.all.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  # 3. 삭제 🗑️
  def destroy
    @vision.destroy
    redirect_to visions_path, notice: "비전이 삭제되었습니다."
  end

  private

  def set_vision
    @vision = Vision.find(params[:id])
  end

  # 💡 타이틀만 허용하도록 단축
  def vision_params
    params.require(:vision).permit(:title)
  end
end
