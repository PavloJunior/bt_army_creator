# Seed data for BT Army Creator

# Eras (from masterunitlist.info filter page)
eras = [
  { mul_id: 10,  name: "Star League",                       start_year: 2571, end_year: 2780, sort_order: 1 },
  { mul_id: 11,  name: "Early Succession War",              start_year: 2781, end_year: 2900, sort_order: 2 },
  { mul_id: 255, name: "Late Succession War - LosTech",     start_year: 2901, end_year: 3019, sort_order: 3 },
  { mul_id: 256, name: "Late Succession War - Renaissance", start_year: 3020, end_year: 3049, sort_order: 4 },
  { mul_id: 13,  name: "Clan Invasion",                     start_year: 3050, end_year: 3061, sort_order: 5 },
  { mul_id: 247, name: "Civil War",                         start_year: 3062, end_year: 3067, sort_order: 6 },
  { mul_id: 14,  name: "Jihad",                             start_year: 3068, end_year: 3080, sort_order: 7 },
  { mul_id: 15,  name: "Early Republic",                    start_year: 3081, end_year: 3100, sort_order: 8 },
  { mul_id: 254, name: "Late Republic",                     start_year: 3101, end_year: 3130, sort_order: 9 },
  { mul_id: 16,  name: "Dark Age",                          start_year: 3131, end_year: 3150, sort_order: 10 },
  { mul_id: 257, name: "ilClan",                            start_year: 3151, end_year: 9999, sort_order: 11 }
]

eras.each do |attrs|
  Era.find_or_create_by!(mul_id: attrs[:mul_id]) do |era|
    era.assign_attributes(attrs)
  end
end
puts "Seeded #{Era.count} eras"

# Factions (from masterunitlist.info /Faction/Autocomplete)
factions = [
  { mul_id: 102, name: "Alyina Mercantile League", category: "Other" },
  { mul_id: 78,  name: "Calderon Protectorate", category: "Periphery" },
  { mul_id: 5,   name: "Capellan Confederation", category: "Inner Sphere" },
  { mul_id: 9,   name: "Circinus Federation", category: "Periphery" },
  { mul_id: 2,   name: "Clan Blood Spirit", category: "Clan" },
  { mul_id: 1,   name: "Clan Burrock", category: "Clan" },
  { mul_id: 6,   name: "Clan Cloud Cobra", category: "Clan" },
  { mul_id: 7,   name: "Clan Coyote", category: "Clan" },
  { mul_id: 8,   name: "Clan Diamond Shark", category: "Clan" },
  { mul_id: 10,  name: "Clan Fire Mandrill", category: "Clan" },
  { mul_id: 11,  name: "Clan Ghost Bear", category: "Clan" },
  { mul_id: 12,  name: "Clan Goliath Scorpion", category: "Clan" },
  { mul_id: 13,  name: "Clan Hell's Horses", category: "Clan" },
  { mul_id: 14,  name: "Clan Ice Hellion", category: "Clan" },
  { mul_id: 15,  name: "Clan Jade Falcon", category: "Clan" },
  { mul_id: 16,  name: "Clan Mongoose", category: "Clan" },
  { mul_id: 17,  name: "Clan Nova Cat", category: "Clan" },
  { mul_id: 100, name: "Clan Protectorate", category: "Clan" },
  { mul_id: 82,  name: "Clan Sea Fox", category: "Clan" },
  { mul_id: 20,  name: "Clan Smoke Jaguar", category: "Clan" },
  { mul_id: 21,  name: "Clan Snow Raven", category: "Clan" },
  { mul_id: 19,  name: "Clan Star Adder", category: "Clan" },
  { mul_id: 22,  name: "Clan Steel Viper", category: "Clan" },
  { mul_id: 80,  name: "Clan Stone Lion", category: "Clan" },
  { mul_id: 25,  name: "Clan Widowmaker", category: "Clan" },
  { mul_id: 24,  name: "Clan Wolf", category: "Clan" },
  { mul_id: 23,  name: "Clan Wolf (in Exile)", category: "Clan" },
  { mul_id: 26,  name: "Clan Wolverine", category: "Clan" },
  { mul_id: 18,  name: "ComStar", category: "Other" },
  { mul_id: 27,  name: "Draconis Combine", category: "Inner Sphere" },
  { mul_id: 84,  name: "Federated Commonwealth", category: "Inner Sphere" },
  { mul_id: 29,  name: "Federated Suns", category: "Inner Sphere" },
  { mul_id: 77,  name: "Filtvelt Coalition", category: "Periphery" },
  { mul_id: 28,  name: "Free Rasalhague Republic", category: "Inner Sphere" },
  { mul_id: 30,  name: "Free Worlds League", category: "Inner Sphere" },
  { mul_id: 59,  name: "Free Worlds League (Duchy of Andurien)", category: "Inner Sphere" },
  { mul_id: 75,  name: "Free Worlds League (Duchy of Tamarind-Abbey)", category: "Inner Sphere" },
  { mul_id: 74,  name: "Free Worlds League (Marik-Stewart Commonwealth)", category: "Inner Sphere" },
  { mul_id: 89,  name: "Free Worlds League (Non-Aligned Worlds)", category: "Inner Sphere" },
  { mul_id: 67,  name: "Free Worlds League (Oriente Protectorate)", category: "Inner Sphere" },
  { mul_id: 72,  name: "Free Worlds League (Regulan Fiefs)", category: "Inner Sphere" },
  { mul_id: 76,  name: "Free Worlds League (Rim Commonality)", category: "Inner Sphere" },
  { mul_id: 95,  name: "Fronc Reaches", category: "Periphery" },
  { mul_id: 85,  name: "HW Clan General", category: "General" },
  { mul_id: 55,  name: "Inner Sphere General", category: "General" },
  { mul_id: 56,  name: "IS Clan General", category: "General" },
  { mul_id: 32,  name: "Lyran Alliance", category: "Inner Sphere" },
  { mul_id: 60,  name: "Lyran Commonwealth", category: "Inner Sphere" },
  { mul_id: 33,  name: "Magistracy of Canopus", category: "Periphery" },
  { mul_id: 35,  name: "Marian Hegemony", category: "Periphery" },
  { mul_id: 34,  name: "Mercenary", category: "Other" },
  { mul_id: 36,  name: "Outworlds Alliance", category: "Periphery" },
  { mul_id: 57,  name: "Periphery General", category: "General" },
  { mul_id: 38,  name: "Pirates", category: "Other" },
  { mul_id: 40,  name: "Rasalhague Dominion", category: "Clan" },
  { mul_id: 39,  name: "Raven Alliance", category: "Clan" },
  { mul_id: 42,  name: "Rim Worlds Republic - Home Guard", category: "Periphery" },
  { mul_id: 88,  name: "Rim Worlds Republic - Terran Corps", category: "Periphery" },
  { mul_id: 44,  name: "Solaris 7", category: "Other" },
  { mul_id: 83,  name: "St. Ives Compact", category: "Inner Sphere" },
  { mul_id: 97,  name: "Star League (Clan Jade Falcon)", category: "Star League" },
  { mul_id: 98,  name: "Star League (Clan Smoke Jaguar)", category: "Star League" },
  { mul_id: 96,  name: "Star League (Clan Wolf)", category: "Star League" },
  { mul_id: 46,  name: "Star League (Second)", category: "Star League" },
  { mul_id: 90,  name: "Star League General", category: "General" },
  { mul_id: 94,  name: "Star League in Exile", category: "Star League" },
  { mul_id: 45,  name: "Star League Regular", category: "Star League" },
  { mul_id: 43,  name: "Star League Royal", category: "Star League" },
  { mul_id: 104, name: "Tamar Pact", category: "Inner Sphere" },
  { mul_id: 47,  name: "Taurian Concordat", category: "Periphery" },
  { mul_id: 87,  name: "Terran Hegemony", category: "Inner Sphere" },
  { mul_id: 105, name: "Vesper Marches", category: "Inner Sphere" },
  { mul_id: 49,  name: "Wolf's Dragoons", category: "Other" },
  { mul_id: 48,  name: "Word of Blake", category: "Other" }
]

factions.each do |attrs|
  Faction.find_or_create_by!(mul_id: attrs[:mul_id]) do |faction|
    faction.assign_attributes(attrs)
  end
end
puts "Seeded #{Faction.count} factions"
