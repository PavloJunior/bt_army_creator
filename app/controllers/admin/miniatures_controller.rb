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

    def bulk_new
    end

    def bulk_create
      count = params[:count].to_i
      if count < 1 || count > 100
        redirect_to admin_chassis_path(@chassis), alert: "Count must be between 1 and 100."
        return
      end

      @chassis.miniatures.insert_all(Array.new(count) { { chassis_id: @chassis.id, created_at: Time.current, updated_at: Time.current } })
      redirect_to admin_chassis_path(@chassis), notice: "#{count} miniature#{'s' if count != 1} added to #{@chassis.name}."
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
