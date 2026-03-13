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

    def search
      search_term = params[:search_term].to_s.strip
      if search_term.blank?
        redirect_to new_admin_chassis_path, alert: "Please enter a search term."
        return
      end

      variants_data = MulClient.fetch_variants(search_term)
      chassis_groups = variants_data
        .group_by { |v| v["Class"] }
        .reject { |name, _| name.blank? }

      if chassis_groups.empty?
        redirect_to new_admin_chassis_path, alert: "No chassis found for '#{search_term}'."
        return
      end

      existing_names = Chassis.where(name: chassis_groups.keys).pluck(:name).to_set
      new_groups = chassis_groups.reject { |name, _| existing_names.include?(name) }

      if new_groups.size == 1
        chassis = Chassis.create!(name: new_groups.keys.first)
        SyncChassisJob.perform_later(chassis.id)
        redirect_to admin_chassis_index_path, notice: "#{chassis.name} added. Syncing variants from MUL..."
        return
      end

      @search_term = search_term
      @existing_names = existing_names
      @chassis_groups = chassis_groups.map do |name, variants|
        first = variants.first
        {
          name: name,
          unit_type: first.dig("Type", "Name"),
          tonnage: first["Tonnage"]&.to_i,
          variant_count: variants.size,
          image_url: first["ImageUrl"]
        }
      end.sort_by { |g| g[:name] }

      render :search_results
    rescue MulClient::ApiError => e
      redirect_to new_admin_chassis_path, alert: "MUL API error: #{e.message}"
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
