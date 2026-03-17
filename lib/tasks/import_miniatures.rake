module ImportResolver
  module_function

  def resolve_chassis_name(name)
    print "Resolving: #{name} ... "

    begin
      results = MulClient.fetch_variants(name)
    rescue MulClient::ApiError => e
      puts "API error: #{e.message}"
      return handle_api_error(name)
    end

    classes = results.map { |r| r["Class"] }.compact.uniq.sort
    variant_counts = results.group_by { |r| r["Class"] }.transform_values(&:count)

    if classes.empty?
      puts "no results found in MUL."
      return handle_no_results(name)
    end

    exact_match = classes.find { |c| c.casecmp(name).zero? }

    if exact_match
      others = classes.size - 1
      suffix = others > 0 ? " (#{others} other chassis also matched)" : ""
      puts "exact match (#{variant_counts[exact_match]} variants#{suffix})"
      return exact_match
    end

    if classes.size == 1
      puts "close match found: #{classes.first} (#{variant_counts[classes.first]} variants)"
      return confirm_single(name, classes.first)
    end

    puts "#{classes.size} chassis found:"
    disambiguate(name, classes, variant_counts)
  end

  def disambiguate(name, classes, variant_counts)
    loop do
      classes.each_with_index do |cls, i|
        puts "  #{i + 1}) #{cls} (#{variant_counts[cls]} variants)"
      end
      puts "  ---"
      puts "  r) Re-search with a different name"
      puts "  s) Skip this chassis"
      puts "  k) Keep \"#{name}\" as-is (may fail to sync)"
      print "Pick [1-#{classes.size}, r, s, k]: "

      input = $stdin.gets
      abort "\nInput ended unexpectedly. Aborting." if input.nil?
      input = input.strip

      case input.downcase
      when /\A(\d+)\z/
        index = $1.to_i - 1
        if index >= 0 && index < classes.size
          puts "  -> #{classes[index]}"
          return classes[index]
        end
        puts "  Invalid number. Try again."
      when "r"
        print "  Enter new search term: "
        new_name = $stdin.gets&.strip
        return resolve_chassis_name(new_name) if new_name.present?
        puts "  Empty name, trying again."
      when "s"
        return nil
      when "k"
        puts "  -> Keeping \"#{name}\" as-is"
        return name
      else
        puts "  Invalid input. Try again."
      end
    end
  end

  def confirm_single(name, found_class)
    loop do
      print "  Use \"#{found_class}\" instead? [y/n/r/s]: "
      input = $stdin.gets
      abort "\nInput ended unexpectedly. Aborting." if input.nil?

      case input.strip.downcase
      when "y"
        puts "  -> #{found_class}"
        return found_class
      when "n"
        puts "  -> Keeping \"#{name}\" as-is"
        return name
      when "r"
        print "  Enter new search term: "
        new_name = $stdin.gets&.strip
        return resolve_chassis_name(new_name) if new_name.present?
        puts "  Empty name, trying again."
      when "s"
        return nil
      else
        puts "  Invalid input. Try again."
      end
    end
  end

  def handle_no_results(name)
    loop do
      puts "  r) Re-search with a different name"
      puts "  s) Skip this chassis"
      puts "  k) Keep \"#{name}\" as-is"
      print "Pick [r, s, k]: "

      input = $stdin.gets
      abort "\nInput ended unexpectedly. Aborting." if input.nil?

      case input.strip.downcase
      when "r"
        print "  Enter new search term: "
        new_name = $stdin.gets&.strip
        return resolve_chassis_name(new_name) if new_name.present?
        puts "  Empty name, trying again."
      when "s"
        return nil
      when "k"
        return name
      else
        puts "  Invalid input. Try again."
      end
    end
  end

  def handle_api_error(name)
    loop do
      puts "  r) Retry"
      puts "  s) Skip this chassis"
      puts "  k) Keep \"#{name}\" as-is"
      print "Pick [r, s, k]: "

      input = $stdin.gets
      abort "\nInput ended unexpectedly. Aborting." if input.nil?

      case input.strip.downcase
      when "r"
        return resolve_chassis_name(name)
      when "s"
        return nil
      when "k"
        return name
      else
        puts "  Invalid input. Try again."
      end
    end
  end
end

namespace :import do
  desc "Parse a mech list text file into JSON with chassis counts. Usage: bin/rails import:parse_mech_list[path/to/mech_list.md]"
  task :parse_mech_list, [ :file_path ] => :environment do |_t, args|
    file_path = args[:file_path]

    if file_path.blank?
      abort "Usage: bin/rails import:parse_mech_list[path/to/mech_list.md]\n" \
            "File should contain one chassis name per line. Duplicates are counted as multiple miniatures.\n" \
            "Lines with '/' (e.g. 'Schrek Gauss Carrier/Schrek PPC Carrier') become linked chassis sharing a miniature pool."
    end

    unless File.exist?(file_path)
      abort "File not found: #{file_path}"
    end

    counts = Hash.new(0)
    File.readlines(file_path).each do |line|
      name = line.strip
      next if name.blank?
      counts[name] += 1
    end

    output_path = file_path.sub(/\.[^.]+\z/, ".json")
    File.write(output_path, JSON.pretty_generate(counts))

    puts "Parsed #{counts.values.sum} entries into #{counts.size} unique chassis/groups:"
    counts.sort_by { |name, _| name }.each do |name, count|
      label = name.include?("/") ? "#{name} (linked group)" : name
      puts "  #{label}: #{count}"
    end
    puts
    puts "Written to: #{output_path}"
    puts "Next step: bin/rails import:resolve[#{output_path}]"
  end

  desc "Resolve chassis names against MUL API interactively. Usage: bin/rails import:resolve[path/to/mech_list.json]"
  task :resolve, [ :file_path ] => :environment do |_t, args|
    file_path = args[:file_path]

    if file_path.blank?
      abort "Usage: bin/rails import:resolve[path/to/mech_list.json]\n" \
            "Queries the MUL API for each chassis name and lets you disambiguate matches.\n" \
            "Modifies the JSON file in-place with corrected names."
    end

    unless File.exist?(file_path)
      abort "File not found: #{file_path}"
    end

    data = JSON.parse(File.read(file_path))

    if data.empty?
      puts "No chassis to resolve."
      next
    end

    unique_names = data.keys.flat_map { |key| key.split("/").map(&:strip) }.uniq
    puts "Resolving #{unique_names.size} unique chassis names against MUL API...\n\n"

    # Phase 1: Resolve each unique name
    resolution_cache = {}
    changes = 0
    skips = 0

    unique_names.each do |name|
      resolved = ImportResolver.resolve_chassis_name(name)
      if resolved.nil?
        resolution_cache[name] = :skip
        skips += 1
      else
        resolution_cache[name] = resolved
        changes += 1 if resolved != name
      end
    end

    # Phase 2: Rebuild JSON with resolved names
    resolved_data = {}
    data.each do |key, count|
      if key.include?("/")
        names = key.split("/").map(&:strip)
        resolved_names = names.map { |n| resolution_cache[n] }.reject { |n| n == :skip }
        if resolved_names.empty?
          puts "\n  Dropping group: #{key} (all names skipped)"
          next
        end
        new_key = resolved_names.join("/")
      else
        resolved = resolution_cache[key.strip]
        if resolved == :skip
          puts "\n  Dropping: #{key}"
          next
        end
        new_key = resolved
      end

      if resolved_data.key?(new_key)
        resolved_data[new_key] += count
        puts "\n  Merged duplicate '#{new_key}': count now #{resolved_data[new_key]}"
      else
        resolved_data[new_key] = count
      end
    end

    # Phase 3: Write results
    puts "\nSummary:"
    puts "  Names resolved: #{unique_names.size}"
    puts "  Names changed: #{changes}"
    puts "  Names skipped: #{skips}"

    if changes > 0 || skips > 0
      File.write(file_path, JSON.pretty_generate(resolved_data))
      puts "  Updated: #{file_path}"
    else
      puts "  No changes needed."
    end

    puts "\nNext step: bin/rails import:miniatures[#{file_path}]"
  end

  desc "Bulk import chassis and miniatures from a JSON file. Usage: bin/rails import:miniatures[path/to/file.json]"
  task :miniatures, [ :file_path ] => :environment do |_t, args|
    file_path = args[:file_path]

    if file_path.blank?
      abort "Usage: bin/rails import:miniatures[path/to/file.json]\n" \
            "File format: {\"Hunchback\": 2, \"Atlas\": 2, \"Timber Wolf\": 1}\n" \
            "Keys with '/' are split into linked chassis sharing a miniature pool."
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
    groups_linked = 0

    data.each do |key, desired_count|
      desired_count = desired_count.to_i

      if key.include?("/")
        names = key.split("/").map(&:strip).reject(&:blank?)
        group_id = SecureRandom.uuid
        groups_linked += 1
        puts "  Linked group: #{names.join(' + ')}"

        chassis_records = names.map do |name|
          chassis = Chassis.find_or_initialize_by(name: name)
          new_chassis = chassis.new_record?

          chassis.mini_group_id = group_id
          chassis.save!

          if new_chassis
            created_chassis << name
            puts "    Created chassis: #{name}"
          else
            existing_chassis << name
            puts "    Found existing chassis: #{name}"
          end

          should_sync = new_chassis || force_sync || chassis.mul_synced_at.nil?
          if should_sync
            SyncChassisJob.perform_later(chassis.id)
            syncs_enqueued += 1
            puts "    Enqueued sync job for #{name}"
          else
            puts "    #{name} already synced (use FORCE_SYNC=1 to re-sync)"
          end

          chassis
        end

        # Shared miniatures go on the first chassis in the group
        pool_chassis = chassis_records.first
        existing_count = pool_chassis.miniatures_pool.count
        to_create = [ desired_count - existing_count, 0 ].max

        if to_create > 0
          to_create.times { pool_chassis.miniatures.create! }
          miniatures_created += to_create
          puts "    Created #{to_create} shared miniature(s) on #{pool_chassis.name}"
        else
          puts "    Pool already has #{existing_count} miniature(s), skipping (requested #{desired_count})"
        end
      else
        chassis = Chassis.find_or_initialize_by(name: key)
        new_chassis = chassis.new_record?

        if new_chassis
          chassis.save!
          created_chassis << key
          puts "  Created chassis: #{key}"
        else
          existing_chassis << key
          puts "  Found existing chassis: #{key}"
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
    end

    puts
    puts "Summary:"
    puts "  Chassis created: #{created_chassis.size} (#{created_chassis.join(', ').presence || 'none'})"
    puts "  Chassis existing: #{existing_chassis.size}"
    puts "  Miniatures created: #{miniatures_created}"
    puts "  Linked groups: #{groups_linked}"
    puts "  Sync jobs enqueued: #{syncs_enqueued}"
  end

  desc "All-in-one: parse, resolve against MUL, and import. Usage: bin/rails import:all[path/to/mech_list.md]"
  task :all, [ :file_path ] => :environment do |_t, args|
    file_path = args[:file_path]

    if file_path.blank?
      abort "Usage: bin/rails import:all[path/to/mech_list.md]"
    end

    json_path = file_path.sub(/\.[^.]+\z/, ".json")

    puts "=== Step 1: Parse mech list ===\n\n"
    Rake::Task["import:parse_mech_list"].invoke(file_path)

    puts "\n=== Step 2: Resolve names against MUL ===\n\n"
    Rake::Task["import:resolve"].invoke(json_path)

    puts "\n=== Step 3: Import chassis and miniatures ===\n\n"
    Rake::Task["import:miniatures"].invoke(json_path)
  end
end
