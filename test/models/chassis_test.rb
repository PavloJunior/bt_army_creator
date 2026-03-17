require "test_helper"

class ChassisTest < ActiveSupport::TestCase
  test "sibling_chassis returns empty for ungrouped chassis" do
    assert_empty chassis(:atlas).sibling_chassis
  end

  test "sibling_chassis returns grouped siblings" do
    gauss = chassis(:schrek_gauss)
    ppc = chassis(:schrek_ppc)

    assert_includes gauss.sibling_chassis, ppc
    assert_includes ppc.sibling_chassis, gauss
  end

  test "group_chassis includes self and siblings" do
    gauss = chassis(:schrek_gauss)
    ppc = chassis(:schrek_ppc)
    group = gauss.group_chassis

    assert_includes group, gauss
    assert_includes group, ppc
  end

  test "group_chassis returns only self for ungrouped chassis" do
    atlas = chassis(:atlas)
    assert_equal [ atlas.id ], atlas.group_chassis.pluck(:id)
  end

  test "miniatures_pool returns own minis for ungrouped chassis" do
    atlas = chassis(:atlas)
    assert_equal atlas.miniatures.pluck(:id).sort, atlas.miniatures_pool.pluck(:id).sort
  end

  test "miniatures_pool returns all group minis for grouped chassis" do
    gauss = chassis(:schrek_gauss)
    ppc = chassis(:schrek_ppc)

    pool_ids = gauss.miniatures_pool.pluck(:id).sort
    assert_equal pool_ids, ppc.miniatures_pool.pluck(:id).sort
    assert_includes pool_ids, miniatures(:schrek_mini_1).id
    assert_includes pool_ids, miniatures(:schrek_mini_2).id
  end

  test "shared_minis? returns false for ungrouped chassis" do
    assert_not chassis(:atlas).shared_minis?
  end

  test "shared_minis? returns true for grouped chassis" do
    assert chassis(:schrek_gauss).shared_minis?
    assert chassis(:schrek_ppc).shared_minis?
  end

  test "shared_minis? returns false for lone group member" do
    lone = Chassis.create!(name: "Lone Wolf", mini_group_id: "orphan-group")
    assert_not lone.shared_minis?
  end
end
