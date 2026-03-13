require "test_helper"

class VariantTest < ActiveSupport::TestCase
  test "for_tech_base inner_sphere returns IS variants via faction" do
    result = Variant.for_tech_base("inner_sphere")
    assert_includes result, variants(:atlas_d)
    assert_not_includes result, variants(:timber_wolf_prime)
  end

  test "for_tech_base clan returns Clan variants via faction" do
    result = Variant.for_tech_base("clan")
    assert_includes result, variants(:timber_wolf_prime)
    assert_not_includes result, variants(:atlas_d)
  end

  test "for_tech_base mixed returns all variants" do
    result = Variant.for_tech_base("mixed")
    assert_includes result, variants(:atlas_d)
    assert_includes result, variants(:timber_wolf_prime)
  end

  test "for_tech_base blank returns all variants" do
    result = Variant.for_tech_base(nil)
    assert_includes result, variants(:atlas_d)
    assert_includes result, variants(:timber_wolf_prime)
  end
end
