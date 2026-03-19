namespace :data do
  desc "Fix chassis with mixed unit types: prompt which type to keep, remove the rest"
  task cleanup_mismatched_variants: :environment do
    fixed = 0

    Chassis.find_each do |chassis|
      type_counts = chassis.variants.where.not(unit_type: [nil, ""]).group(:unit_type).count
      next if type_counts.size <= 1

      puts "\n#{"=" * 60}"
      puts "#{chassis.name} (chassis unit_type: #{chassis.unit_type.inspect})"
      puts "Has variants of multiple unit types:"
      type_counts.sort_by { |_, count| -count }.each_with_index do |(type, count), i|
        puts "  #{i + 1}. #{type} (#{count} variants)"
      end

      types = type_counts.sort_by { |_, count| -count }.map(&:first)
      choice = nil
      loop do
        print "Which type to KEEP? [1-#{types.size}] or 's' to skip: "
        input = $stdin.gets&.strip
        if input == "s"
          puts "Skipping #{chassis.name}."
          break
        end
        index = input.to_i - 1
        if index >= 0 && index < types.size
          choice = types[index]
          break
        end
        puts "Invalid choice."
      end
      next unless choice

      wrong_variants = chassis.variants.where.not(unit_type: choice)
      puts "Removing #{wrong_variants.count} variants (keeping #{choice}):"
      wrong_variants.each do |variant|
        puts "  - #{variant.name} (#{variant.unit_type}, mul_id: #{variant.mul_id})"
      end
      wrong_variants.destroy_all

      if chassis.unit_type != choice
        puts "Updating chassis unit_type: #{chassis.unit_type.inspect} -> #{choice}"
        chassis.update!(unit_type: choice)
      end

      fixed += 1
    end

    if fixed == 0
      puts "No chassis with mixed unit types found."
    else
      puts "\nDone. Fixed #{fixed} chassis."
    end
  end
end
