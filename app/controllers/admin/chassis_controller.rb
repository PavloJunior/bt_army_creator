module Admin
  class ChassisController < BaseController
    before_action :set_chassis, only: [ :show, :edit, :update, :destroy, :sync_variants, :link, :unlink ]

    def index
      @chassis = Chassis.order(:name).includes(:variants, :miniatures)

      # Precompute pool sizes to avoid N+1 queries for shared mini groups
      group_ids = @chassis.filter_map(&:mini_group_id).uniq
      group_counts = if group_ids.any?
        Miniature.joins(:chassis)
          .where(chassis: { mini_group_id: group_ids })
          .group("chassis.mini_group_id")
          .count
      else
        {}
      end

      @mini_pool_sizes = @chassis.each_with_object({}) do |c, h|
        h[c.id] = if c.mini_group_id.present?
          group_counts[c.mini_group_id] || 0
        else
          c.miniatures.size # uses eager-loaded association
        end
      end
    end

    def show
      @variants = @chassis.variants.order(:name).includes(:variant_cards)
      @miniatures = @chassis.miniatures.order(:label)
      @pool_miniatures = @chassis.miniatures_pool.includes(:chassis).order(:id)
      @sibling_chassis = @chassis.sibling_chassis.order(:name)
      @linkable_chassis = Chassis.where.not(id: @chassis.group_chassis_ids).order(:name)
    end

    def new
      @chassis = Chassis.new
    end

    def create
      @chassis = Chassis.new(chassis_params)
      if @chassis.save
        create_miniatures(@chassis, params[:miniature_count])
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
        .reject { |v| v["Class"].blank? }
        .group_by { |v| [ v["Class"], v.dig("Type", "Name") ] }

      if chassis_groups.empty?
        redirect_to new_admin_chassis_path, alert: "No chassis found for '#{search_term}'."
        return
      end

      existing_pairs = Chassis.where(name: chassis_groups.keys.map(&:first).uniq)
        .pluck(:name, :unit_type)
        .to_set
      new_groups = chassis_groups.reject { |(name, unit_type), _| existing_pairs.include?([ name, unit_type ]) }

      if new_groups.size == 1
        name, unit_type = new_groups.keys.first
        chassis = Chassis.create!(name: name, unit_type: unit_type)
        create_miniatures(chassis, params[:miniature_count])
        SyncChassisJob.perform_later(chassis.id)
        redirect_to admin_chassis_index_path, notice: "#{chassis.name} added. Syncing variants from MUL..."
        return
      end

      @search_term = search_term
      @existing_pairs = existing_pairs
      @chassis_groups = chassis_groups.map do |(name, unit_type), variants|
        first = variants.first
        {
          name: name,
          unit_type: unit_type,
          tonnage: first["Tonnage"]&.to_i,
          variant_count: variants.size,
          image_url: first["ImageUrl"]
        }
      end.sort_by { |g| [ g[:name], g[:unit_type].to_s ] }

      render :search_results
    rescue MulClient::ApiError => e
      redirect_to new_admin_chassis_path, alert: "MUL API error: #{e.message}"
    end

    def batch_create
      entries = Array(params[:chassis_entries]).reject(&:blank?).map { |e| e.split("||", 2) }
      if entries.empty?
        redirect_to new_admin_chassis_path, alert: "No chassis selected."
        return
      end

      mini_count = params[:miniature_count].to_i
      shared = params[:shared] == "true"
      group_id = shared ? SecureRandom.uuid : nil

      created = []
      Chassis.transaction do
        entries.each do |name, unit_type|
          next if Chassis.exists?(name: name, unit_type: unit_type)
          chassis = Chassis.create!(name: name, unit_type: unit_type, mini_group_id: group_id)
          create_miniatures(chassis, mini_count) unless shared
          created << chassis
        end

        if shared && created.any?
          create_miniatures(created.first, mini_count)
        end
      end

      created.each { |c| SyncChassisJob.perform_later(c.id) }

      notice = "#{created.size} chassis added."
      notice += " Sharing miniatures." if shared && created.size > 1
      redirect_to admin_chassis_index_path, notice: notice
    end

    def link
      target = Chassis.find(params[:target_chassis_id])
      group_id = @chassis.mini_group_id || target.mini_group_id || SecureRandom.uuid

      Chassis.transaction do
        if @chassis.mini_group_id.present? && target.mini_group_id.present? && @chassis.mini_group_id != target.mini_group_id
          Chassis.where(mini_group_id: target.mini_group_id).update_all(mini_group_id: group_id)
        end

        @chassis.update!(mini_group_id: group_id)
        target.update!(mini_group_id: group_id)
      end

      redirect_to admin_chassis_path(@chassis), notice: "#{target.name} linked to #{@chassis.name}'s miniature pool."
    end

    def unlink
      old_group_id = @chassis.mini_group_id

      Chassis.transaction do
        @chassis.update!(mini_group_id: nil)

        if old_group_id.present?
          remaining = Chassis.where(mini_group_id: old_group_id)
          remaining.first.update!(mini_group_id: nil) if remaining.count == 1
        end
      end

      redirect_to admin_chassis_path(@chassis), notice: "#{@chassis.name} removed from sharing group."
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
      params.require(:chassis).permit(:name, :unit_type)
    end

    def create_miniatures(chassis, count)
      count = count.to_i
      return unless count > 0

      count.times { chassis.miniatures.create! }
    end
  end
end
