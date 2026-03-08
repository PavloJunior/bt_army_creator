require "test_helper"

class VariantCardTest < ActiveSupport::TestCase
  test "valid with variant and skill" do
    card = VariantCard.new(variant: variants(:commando_2d), skill: 4)
    assert card.valid?
  end

  test "requires skill" do
    card = VariantCard.new(variant: variants(:commando_2d), skill: nil)
    assert_not card.valid?
    assert card.errors[:skill].any?
  end

  test "skill must be between 0 and 8" do
    card = VariantCard.new(variant: variants(:commando_2d))

    card.skill = -1
    assert_not card.valid?

    card.skill = 9
    assert_not card.valid?

    card.skill = 0
    assert card.valid?

    card.skill = 8
    assert card.valid?
  end

  test "enforces uniqueness on variant and skill" do
    # atlas_d_skill4 fixture already exists
    duplicate = VariantCard.new(variant: variants(:atlas_d), skill: 4)
    assert_not duplicate.valid?
    assert duplicate.errors[:variant_id].any?
  end

  test "allows different skills for same variant" do
    # atlas_d_skill4 fixture exists with skill 4
    different = VariantCard.new(variant: variants(:atlas_d), skill: 3)
    assert different.valid?
  end
end
