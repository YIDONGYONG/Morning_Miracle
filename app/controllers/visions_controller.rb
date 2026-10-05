class VisionsController < ApplicationController
  before_action :set_vision, only: [ :show, :edit, :update, :destroy ]

  # 1. 一覧表示
  def index
    @visions = current_user.visions.order(:id)
  end

  # 2. 詳細表示
  def show; end

  # 3. 新規作成フォーム
  def new
    @vision = Vision.new
  end

  # 3. 新規作成（DB保存）
  def create
    @vision = current_user.visions.build(vision_params)

    if @vision.save
      redirect_to @vision, notice: "ビジョンを登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # 4. 編集フォーム
  def edit; end

  # 4. 更新（DB保存）
  def update
    if @vision.update(vision_params)
      redirect_to @vision, notice: "ビジョンを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 5. 削除
  def destroy
    @vision.destroy
    redirect_to visions_path, status: :see_other, notice: "ビジョンを削除しました"
  end

  private

  # 対象のビジョンを取得する共通処理（自分のビジョンだけ。他人のIDは404）
  def set_vision
    @vision = current_user.visions.find(params[:id])
  end

  def vision_params
    params.require(:vision).permit(:title, :content, :target_date)
  end
end
