namespace :verify do
  desc "Check each Chassis has the correct unit type, tonnage, and variant assignments vs MUL API"
  task chassis_identity: :environment do
    checked = 0
    issues = 0

    puts "Verifying chassis identity against MUL API..."
    puts

    Chassis.order(:name).find_each do |chassis|
      checked += 1
      problems = []

      begin
        all_variants = MulClient.fetch_variants(chassis.name)
      rescue MulClient::ApiError => e
        puts "[ERROR] #{chassis.name} (id: #{chassis.id}) — API error: #{e.message}"
        issues += 1
        sleep 0.5
        next
      end

      # Filter to exact class name match (same as SyncChassisJob)
      all_variants = all_variants.select { |d| d["Class"]&.casecmp(chassis.name)&.zero? }

      if all_variants.empty?
        puts "[WARN] #{chassis.name} (id: #{chassis.id}) — no MUL results match class name"
        issues += 1
        sleep 0.5
        next
      end

      # Group by unit type
      by_type = all_variants.group_by { |d| d.dig("Type", "Name") }

      if by_type.size > 1 && chassis.unit_type.blank?
        problems << "  MUL has #{by_type.size} unit types for \"#{chassis.name}\": " \
                     "#{by_type.map { |t, vs| "#{t} (#{vs.size} variants)" }.join(", ")}"
        problems << "  Chassis unit_type is BLANK — cannot disambiguate"
      elsif by_type.size > 1
        problems << "  MUL has #{by_type.size} unit types for \"#{chassis.name}\": " \
                     "#{by_type.map { |t, vs| "#{t} (#{vs.size} variants)" }.join(", ")}"
        unless by_type.key?(chassis.unit_type)
          problems << "  Chassis unit_type '#{chassis.unit_type}' not found in MUL results!"
        end
      end

      # Filter to matching unit type (same as SyncChassisJob)
      expected_variants = if chassis.unit_type.present?
        all_variants.select { |d| d.dig("Type", "Name") == chassis.unit_type }
      else
        all_variants
      end

      expected_mul_ids = expected_variants.map { |d| d["Id"] }.to_set
      expected_by_mul_id = expected_variants.index_by { |d| d["Id"] }

      # Check tonnage
      if expected_variants.any?
        api_tonnage = expected_variants.first["Tonnage"]&.to_i
        if chassis.tonnage.present? && api_tonnage.present? && chassis.tonnage != api_tonnage
          problems << "  Tonnage mismatch: DB=#{chassis.tonnage}, MUL=#{api_tonnage}"
        end
      end

      # Check DB variants
      db_variants = chassis.variants.to_a
      db_mul_ids = db_variants.map(&:mul_id).to_set

      # Variants in DB whose unit_type doesn't match chassis
      if chassis.unit_type.present?
        mismatched = db_variants.select { |v| v.unit_type.present? && v.unit_type != chassis.unit_type }
        if mismatched.any?
          problems << "  #{mismatched.size} variant(s) with wrong unit_type:"
          mismatched.each do |v|
            problems << "    - #{v.name} (mul_id: #{v.mul_id}) — DB: #{v.unit_type}, expected: #{chassis.unit_type}"
          end
        end
      end

      # Variants in DB not found in expected API results
      orphaned_mul_ids = db_mul_ids - expected_mul_ids
      if orphaned_mul_ids.any?
        orphaned = db_variants.select { |v| orphaned_mul_ids.include?(v.mul_id) }
        problems << "  #{orphaned.size} DB variant(s) not in expected MUL results:"
        orphaned.each do |v|
          problems << "    - #{v.name} (mul_id: #{v.mul_id}, unit_type: #{v.unit_type})"
        end
      end

      # Check for data drift on matching variants
      drifted = []
      db_variants.each do |v|
        api = expected_by_mul_id[v.mul_id]
        next unless api

        diffs = []
        diffs << "BV: #{v.battle_value}→#{api["BattleValue"]}" if v.battle_value != api["BattleValue"]
        diffs << "PV: #{v.point_value}→#{api["BFPointValue"]}" if v.point_value != api["BFPointValue"]
        diffs << "tonnage: #{v.tonnage}→#{api["Tonnage"]&.to_i}" if v.tonnage != api["Tonnage"]&.to_i
        api_unit_type = api.dig("Type", "Name")
        diffs << "unit_type: #{v.unit_type}→#{api_unit_type}" if v.unit_type != api_unit_type

        drifted << "    - #{v.name} (mul_id: #{v.mul_id}): #{diffs.join(", ")}" if diffs.any?
      end
      if drifted.any?
        problems << "  #{drifted.size} variant(s) with data drift:"
        problems.concat(drifted)
      end

      if problems.any?
        issues += 1
        puts "[WARN] #{chassis.name} (id: #{chassis.id}, unit_type: #{chassis.unit_type.inspect})"
        problems.each { |p| puts p }
        puts
      else
        print "."
      end

      sleep 0.5
    end

    puts
    puts "Done. #{checked} chassis checked, #{issues} issue(s) found."
  end

  desc "Check all Chassis have all available MUL variants present in the database"
  task variant_completeness: :environment do
    checked = 0
    missing_count = 0
    orphan_count = 0

    puts "Checking variant completeness..."
    puts

    Chassis.order(:name).find_each do |chassis|
      checked += 1

      begin
        all_variants = MulClient.fetch_variants(chassis.name)
      rescue MulClient::ApiError => e
        puts "[ERROR] #{chassis.name} (id: #{chassis.id}) — API error: #{e.message}"
        sleep 0.5
        next
      end

      # Filter same as SyncChassisJob
      all_variants = all_variants.select { |d| d["Class"]&.casecmp(chassis.name)&.zero? }
      if chassis.unit_type.present?
        all_variants = all_variants.select { |d| d.dig("Type", "Name") == chassis.unit_type }
      end

      api_mul_ids = all_variants.map { |d| d["Id"] }.to_set
      api_by_mul_id = all_variants.index_by { |d| d["Id"] }
      db_mul_ids = chassis.variants.pluck(:mul_id).to_set

      missing_ids = api_mul_ids - db_mul_ids
      orphaned_ids = db_mul_ids - api_mul_ids

      has_issue = false

      if missing_ids.any?
        missing_count += 1
        has_issue = true
        puts "[MISSING] #{chassis.name} (id: #{chassis.id}) — #{missing_ids.size} variant(s) in MUL not in DB:"
        missing_ids.each do |mul_id|
          d = api_by_mul_id[mul_id]
          puts "  - #{d["Name"]} (mul_id: #{mul_id}, BV: #{d["BattleValue"]}, PV: #{d["BFPointValue"]})"
        end
      end

      if orphaned_ids.any?
        orphan_count += 1
        has_issue = true
        orphaned = chassis.variants.where(mul_id: orphaned_ids.to_a)
        puts "[ORPHAN] #{chassis.name} (id: #{chassis.id}) — #{orphaned_ids.size} variant(s) in DB not in MUL:"
        orphaned.each do |v|
          puts "  - #{v.name} (mul_id: #{v.mul_id})"
        end
      end

      puts if has_issue
      print "." unless has_issue

      sleep 0.5
    end

    puts
    puts "Done. #{checked} chassis checked, #{missing_count} with missing variants, #{orphan_count} with orphaned variants."
  end
end
