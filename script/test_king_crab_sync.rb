chassis = Chassis.find_or_create_by!(name: "King Crab")
puts "Chassis created: #{chassis.name} (id: #{chassis.id})"

puts "\nFetching variants from MUL..."
SyncChassisJob.perform_now(chassis.id)

chassis.reload
puts "\nSynced #{chassis.variants.count} variants:"
chassis.variants.order(:name).each do |v|
  puts "  #{v.name} (mul_id: #{v.mul_id}) - BV: #{v.battle_value}, PV: #{v.point_value}, #{v.tonnage}t"
end

puts "\nNow fetching Skill 4 card images..."
chassis.variants.each do |variant|
  print "  Fetching card for #{variant.name} (mul_id: #{variant.mul_id})..."
  begin
    FetchVariantCardJob.perform_now(variant.id, skill: 4)
    card = VariantCard.find_by(variant: variant, skill: 4)
    if card&.image&.attached?
      puts " Saved! (#{card.image.byte_size} bytes, #{card.image.content_type})"
    else
      puts " No image attached"
    end
  rescue => e
    puts " ERROR: #{e.message}"
  end
end

puts "\nDone! #{VariantCard.where(variant: chassis.variants).count} card images stored."
