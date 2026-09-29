class RoutinesController < ApplicationController
    before_action :set_routine, only: %i[edit update]

    def index
        @routines = current_user.routines
    end

    def show
        @routines = Routines.find(params[:id])
    end
    
    def new
        @routines = Routines.new
    end

    def create
      @routine = current_user.routines.build(routine_params)
      if @routine.save
        redirect_to routines_path, notice: '루틴이 추가되었습니다.'
      else
        render :new, status: :unprocessable_entity
      end
    end
    
    def edit
  # set_routine で @routine が既にセットされている
    end

    def update
      if @routine.update(routine_params)
       redirect_to routines_path, notice: '更新しました'
     else
       render :edit, status: :unprocessable_entity
    end
   end
    private
  
    def set_routine
      # 🔒 타인의 Routine ID를 URL에 주입해도 ActiveRecord::RecordNotFound (404) 발생
      @routine = current_user.routines.find(params[:id])
    end
  
    def routine_params
      params.require(:routine).permit(:title, :category, :completed)
    end
  end


  