namespace :import do
  desc "Bulk import chassis and miniatures from a JSON file. Usage: bin/rails import:miniatures[path/to/file.json]"
  task :miniatures, [ :file_path ] => :environment do |_t, args|
    file_path = args[:file_path]

    if file_path.blank?
      abort "Usage: bin/rails import:miniatures[path/to/file.json]\n" \
            "File format: {\"Hunchback\": 2, \"Atlas\": 2, \"Timber Wolf\": 1}"
    end

    unless File.exist?(file_path)
      abort "File not found: #{file_path}"
    end

    data = JSON.parse(File.read(file_path))
    force_sync = ENV["FORCE_SYNC"] == "1"

    created_chassis = []
    existing_chassis = []
    miniatures_created = 0
    syncs_enqueued = 0

    data.each do |name, desired_count|
      desired_count = desired_count.to_i
      chassis = Chassis.find_or_initialize_by(name: name)
      new_chassis = chassis.new_record?

      if new_chassis
        chassis.save!
        created_chassis << name
        puts "  Created chassis: #{name}"
      else
        existing_chassis << name
        puts "  Found existing chassis: #{name}"
      end

      existing_count = chassis.miniatures.count
      to_create = [ desired_count - existing_count, 0 ].max

      if to_create > 0
        to_create.times { chassis.miniatures.create! }
        miniatures_created += to_create
        puts "    Created #{to_create} miniature(s)"
      else
        puts "    Already has #{existing_count} miniature(s), skipping (requested #{desired_count})"
      end

      should_sync = new_chassis || force_sync || chassis.mul_synced_at.nil?
      if should_sync
        SyncChassisJob.perform_later(chassis.id)
        syncs_enqueued += 1
        puts "    Enqueued sync job"
      else
        puts "    Already synced (use FORCE_SYNC=1 to re-sync)"
      end
    end

    puts
    puts "Summary:"
    puts "  Chassis created: #{created_chassis.size} (#{created_chassis.join(', ').presence || 'none'})"
    puts "  Chassis existing: #{existing_chassis.size}"
    puts "  Miniatures created: #{miniatures_created}"
    puts "  Sync jobs enqueued: #{syncs_enqueued}"
  end
end
