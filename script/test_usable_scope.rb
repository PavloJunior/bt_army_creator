c = Chassis.find_by(name: "King Crab")
puts "All variants: #{c.variants.count}"
puts "Usable: #{c.variants.usable.count}"
puts "Unusable: #{c.variants.unusable.count}"
c.variants.unusable.each { |v| puts "  #{v.name} (BV:#{v.battle_value} PV:#{v.point_value})" }
