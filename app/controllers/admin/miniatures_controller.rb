module Admin
  class MiniaturesController < BaseController
    before_action :set_chassis
    before_action :set_miniature, only: [ :edit, :update, :destroy ]

    def new
      @miniature = @chassis.miniatures.build
    end

    def create
      @miniature = @chassis.miniatures.build(miniature_params)
      if @miniature.save
        redirect_to admin_chassis_index_path, notice: "Miniature added to #{@chassis.name}."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @miniature.update(miniature_params)
        redirect_to admin_chassis_index_path, notice: "Miniature updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @miniature.destroy
        redirect_to admin_chassis_index_path, notice: "Miniature deleted."
      else
        redirect_to admin_chassis_index_path, alert: @miniature.errors.full_messages.join(", ")
      end
    end

    private

    def set_chassis
      @chassis = Chassis.find(params[:chassis_id])
    end

    def set_miniature
      @miniature = @chassis.miniatures.find(params[:id])
    end

    def miniature_params
      params.require(:miniature).permit(:label, :notes)
    end
  end
end
