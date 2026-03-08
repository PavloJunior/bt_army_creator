module Admin
  class ChassisController < BaseController
    before_action :set_chassis, only: [ :show, :edit, :update, :destroy, :sync_variants ]

    def index
      @chassis = Chassis.order(:name).includes(:variants, :miniatures)
    end

    def show
      @variants = @chassis.variants.order(:name).includes(:variant_cards)
      @miniatures = @chassis.miniatures.order(:label)
    end

    def new
      @chassis = Chassis.new
    end

    def create
      @chassis = Chassis.new(chassis_params)
      if @chassis.save
        SyncChassisJob.perform_later(@chassis.id)
        redirect_to admin_chassis_index_path, notice: "#{@chassis.name} added. Syncing variants from MUL..."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @chassis.update(chassis_params)
        redirect_to admin_chassis_index_path, notice: "#{@chassis.name} updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @chassis.destroy
        redirect_to admin_chassis_index_path, notice: "#{@chassis.name} deleted."
      else
        redirect_to admin_chassis_index_path, alert: @chassis.errors.full_messages.join(", ")
      end
    end

    def sync_variants
      SyncChassisJob.perform_later(@chassis.id)
      redirect_to admin_chassis_path(@chassis), notice: "Syncing variants for #{@chassis.name}..."
    end

    private

    def set_chassis
      @chassis = Chassis.find(params[:id])
    end

    def chassis_params
      params.require(:chassis).permit(:name)
    end
  end
end
