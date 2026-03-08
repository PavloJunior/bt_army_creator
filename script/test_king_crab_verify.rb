chassis = Chassis.find_by!(name: "King Crab")

# Fill in any missing cards
chassis.variants.each do |variant|
  card = VariantCard.find_by(variant: variant, skill: 4)
  next if card&.image&.attached?

  print "  Fetching card for #{variant.name} (mul_id: #{variant.mul_id})..."
  begin
    FetchVariantCardJob.perform_now(variant.id, skill: 4)
    card = VariantCard.find_by(variant: variant, skill: 4)
    if card&.image&.attached?
      puts " Saved! (#{card.image.byte_size} bytes)"
    else
      puts " No image"
    end
  rescue => e
    puts " ERROR: #{e.message}"
  end
end

puts "\nAll King Crab cards:"
chassis.variants.order(:name).each do |v|
  card = v.card_for_skill(4)
  status = if card&.image&.attached?
    "#{card.image.byte_size} bytes (#{card.image.content_type})"
  else
    "NO IMAGE"
  end
  puts "  #{v.name}: #{status}"
end

# Copy one card to /tmp for viewing
sample = chassis.variants.joins(:variant_cards).merge(VariantCard.where(skill: 4)).first
if sample
  card = sample.card_for_skill(4)
  path = "/tmp/king_crab_#{sample.variant_code.downcase.gsub(/[^a-z0-9]/, '_')}_skill4.jpg"
  File.open(path, "wb") { |f| f.write(card.image.download) }
  puts "\nSample card saved to: #{path}"
end
