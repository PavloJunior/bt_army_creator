require "test_helper"

class ArmyListTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  test "total_points for alpha_strike reflects skill adjustments" do
    list = army_lists(:draft_list)
    assert_equal "alpha_strike", list.event.game_system

    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 3
    )

    # Atlas PV 52 at skill 3 → 62 (bracket +10 per rating, 1 rating above default)
    assert_equal 62, list.total_points
  end

  test "tech_base defaults to mixed" do
    list = ArmyList.new(event: events(:upcoming_event), player_name: "Player")
    assert_equal "mixed", list.tech_base
  end

  test "tech_base must be valid" do
    list = army_lists(:draft_list)
    list.tech_base = "invalid"
    assert_not list.valid?
    assert list.errors[:tech_base].any?
  end

  test "tech_base_label returns human-readable labels" do
    list = army_lists(:draft_list)
    list.tech_base = "inner_sphere"
    assert_equal "Inner Sphere", list.tech_base_label

    list.tech_base = "clan"
    assert_equal "Clan", list.tech_base_label

    list.tech_base = "mixed"
    assert_equal "Mixed", list.tech_base_label
  end

  test "total_points for classic_bt ignores skill adjustments" do
    list = ArmyList.create!(
      event: events(:active_event),
      player_name: "Classic Player",
      status: "draft"
    )
    assert_equal "classic_bt", list.event.game_system

    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 3
    )

    # Classic BT uses battle_value regardless of skill
    assert_equal 1897, list.total_points
  end

  test "all_cards_ready? returns true when all items have card images" do
    list = army_lists(:draft_list)
    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 3
    )

    card = VariantCard.create!(variant: variants(:atlas_d), skill: 3)
    card.image.attach(io: StringIO.new("img"), filename: "card.jpg", content_type: "image/jpeg")

    assert list.all_cards_ready?
    assert_equal 0, list.pending_cards_count
  end

  test "all_cards_ready? returns false when card image is missing" do
    list = army_lists(:draft_list)
    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 3
    )

    assert_not list.all_cards_ready?
    assert_equal 1, list.pending_cards_count
  end

  test "submit! enqueues FetchVariantCardJob for items without cards" do
    list = army_lists(:draft_list)
    list.event.update!(status: "active")
    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 3
    )

    assert_enqueued_with(job: FetchVariantCardJob, args: [ variants(:atlas_d).id, { skill: 3 } ]) do
      list.submit!
    end
  end

  test "submit! does not enqueue job when card already exists" do
    list = army_lists(:draft_list)
    list.event.update!(status: "active")
    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 3
    )

    card = VariantCard.create!(variant: variants(:atlas_d), skill: 3)
    card.image.attach(io: StringIO.new("img"), filename: "card.jpg", content_type: "image/jpeg")

    assert_no_enqueued_jobs(only: FetchVariantCardJob) do
      list.submit!
    end
  end

  test "pending_cards_count counts items with card record but no attached image" do
    list = army_lists(:draft_list)
    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 4
    )

    # Fixture atlas_d_skill4 exists but has no image attached
    assert_equal 1, list.pending_cards_count
  end

  test "inactive? returns true for inactive status" do
    list = army_lists(:inactive_list)
    assert list.inactive?
    assert_not list.draft?
    assert_not list.submitted?
  end

  test "inactive status is valid" do
    list = army_lists(:draft_list)
    list.status = "inactive"
    assert list.valid?
  end

  test "deactivate! destroys locks and sets status to inactive" do
    list = army_lists(:draft_list)
    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 4
    )
    list.submit!

    assert list.submitted?
    assert_equal 1, list.miniature_locks.count
    submitted_at = list.submitted_at

    list.deactivate!
    list.reload

    assert list.inactive?
    assert_equal 0, list.miniature_locks.count
    assert_equal submitted_at, list.submitted_at
  end

  test "reactivate! creates locks and sets status to submitted" do
    list = army_lists(:draft_list)
    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 4
    )
    list.submit!
    list.deactivate!

    assert list.inactive?
    assert_equal 0, list.miniature_locks.count

    list.reactivate!
    list.reload

    assert list.submitted?
    assert_equal 1, list.miniature_locks.count
  end

  test "reactivate! raises LockConflictError when miniatures are locked" do
    list = army_lists(:draft_list)
    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 4
    )
    list.submit!
    list.deactivate!

    # Another list locks the same miniature
    other_list = ArmyList.create!(
      event: list.event,
      player_name: "Other Player",
      status: "draft",
      tech_base: "mixed"
    )
    other_list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 4
    )
    other_list.submit!

    assert_raises(ArmyList::LockConflictError) do
      list.reactivate!
    end
  end

  test "effective_point_cap returns event cap when bonus is zero" do
    list = army_lists(:draft_list)
    assert_equal 0, list.bonus_points
    assert_equal list.event.point_cap, list.effective_point_cap
  end

  test "effective_point_cap adds positive bonus to event cap" do
    list = army_lists(:draft_list)
    list.bonus_points = 50
    assert_equal list.event.point_cap + 50, list.effective_point_cap
  end

  test "effective_point_cap subtracts negative bonus from event cap" do
    list = army_lists(:draft_list)
    list.bonus_points = -50
    assert_equal list.event.point_cap - 50, list.effective_point_cap
  end

  test "points_remaining accounts for bonus_points" do
    list = army_lists(:draft_list)
    list.bonus_points = 100
    assert_equal list.effective_point_cap, list.points_remaining
  end

  test "submit! allows submission when total under effective cap with bonus" do
    list = army_lists(:draft_list)
    list.event.update!(point_cap: 50)
    list.bonus_points = 20
    list.save!

    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 4
    )

    # Atlas PV 52 > base cap 50, but effective cap is 70
    assert_nothing_raised { list.submit! }
    assert list.reload.submitted?
  end

  test "submit! rejects submission when total exceeds effective cap" do
    list = army_lists(:draft_list)
    list.event.update!(point_cap: 50)
    list.bonus_points = 0
    list.save!

    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 4
    )

    # Atlas PV 52 > cap 50
    assert_raises(ArmyList::PointCapExceededError) { list.submit! }
  end

  test "bonus_points cannot reduce effective cap below 1" do
    list = army_lists(:draft_list)
    list.bonus_points = -list.event.point_cap
    assert_not list.valid?
    assert list.errors[:bonus_points].any?
  end

  # --- effective_point_cap with themed events ---

  test "effective_point_cap uses event.point_cap for standard (non-themed) events" do
    list = army_lists(:draft_list)
    assert_nil list.event_side
    assert_equal list.event.point_cap, list.effective_point_cap
  end

  test "effective_point_cap uses event_side.per_player_point_cap for themed events" do
    side = event_sides(:comstar_side)
    list = ArmyList.create!(
      event: side.event,
      event_side: side,
      player_name: "Themed Player",
      status: "draft",
      tech_base: "mixed"
    )

    # Only one player on this side, so per_player_point_cap == point_cap (300)
    assert_equal 300, list.effective_point_cap
  end

  test "effective_point_cap reflects changing player count on side" do
    side = event_sides(:comstar_side)
    list1 = ArmyList.create!(
      event: side.event,
      event_side: side,
      player_name: "Player 1",
      status: "draft",
      tech_base: "mixed"
    )

    # 1 player -> per_player_point_cap = 300
    assert_equal 300, list1.effective_point_cap

    ArmyList.create!(
      event: side.event,
      event_side: side,
      player_name: "Player 2",
      status: "draft",
      tech_base: "mixed"
    )

    # 2 players -> per_player_point_cap = 150
    assert_equal 150, list1.effective_point_cap
  end

  test "effective_point_cap with event_side includes bonus_points" do
    side = event_sides(:comstar_side)
    list = ArmyList.create!(
      event: side.event,
      event_side: side,
      player_name: "Bonus Player",
      status: "draft",
      tech_base: "mixed",
      bonus_points: 25
    )

    # 1 player: per_player_point_cap = 300, + bonus 25 = 325
    assert_equal 325, list.effective_point_cap
  end

  # =========================================================================
  # Shared army list
  # =========================================================================

  test "#shared? reflects event.shared_army_list?" do
    assert_not army_lists(:draft_list).shared?
    assert army_lists(:shared_list).shared?
  end

  test "shared list has has_many shared_participants association" do
    list = army_lists(:shared_list)
    assert_respond_to list, :shared_participants
    assert_equal 0, list.shared_participants.count
  end

  test "#active_participants excludes participants with left_at set" do
    list = army_lists(:shared_list)
    active = list.shared_participants.create!(display_name: "Alice")
    left = list.shared_participants.create!(display_name: "Bob")
    left.update!(left_at: Time.current)

    assert_includes list.active_participants, active
    assert_not_includes list.active_participants, left
  end

  test "#all_accepted? is false when there are no participants" do
    list = army_lists(:shared_list)
    assert_not list.all_accepted?
  end

  test "#all_accepted? is false when any active participant has not accepted" do
    list = army_lists(:shared_list)
    list.shared_participants.create!(display_name: "Alice", accepted_at: Time.current)
    list.shared_participants.create!(display_name: "Bob") # not accepted

    assert_not list.all_accepted?
  end

  test "#all_accepted? is true when every active participant has accepted" do
    list = army_lists(:shared_list)
    alice = list.shared_participants.create!(display_name: "Alice")
    bob = list.shared_participants.create!(display_name: "Bob")
    alice.accept!
    bob.accept!

    assert list.reload.all_accepted?
  end

  test "#all_accepted? ignores participants who have left" do
    list = army_lists(:shared_list)
    alice = list.shared_participants.create!(display_name: "Alice")
    bob = list.shared_participants.create!(display_name: "Bob")
    bob.leave!
    alice.accept!

    assert list.reload.all_accepted?, "left participants should not block acceptance"
  end

  test "a new participant joining clears other participants' acceptances" do
    list = army_lists(:shared_list)
    alice = list.shared_participants.create!(display_name: "Alice")
    alice.accept!
    assert alice.reload.accepted?

    list.shared_participants.create!(display_name: "Bob")
    assert_nil alice.reload.accepted_at,
      "new participant joining must reset prior acceptances"
  end

  test "a participant leaving clears other participants' acceptances" do
    list = army_lists(:shared_list)
    alice = list.shared_participants.create!(display_name: "Alice")
    bob = list.shared_participants.create!(display_name: "Bob")
    alice.accept!
    bob.accept!
    assert list.reload.all_accepted?

    carol = list.shared_participants.create!(display_name: "Carol")
    alice.accept!
    bob.accept!
    carol.accept!
    assert list.reload.all_accepted?

    carol.leave!
    assert_nil alice.reload.accepted_at
    assert_nil bob.reload.accepted_at
  end

  test "submit! on shared list raises LockConflictError when not all accepted" do
    list = army_lists(:shared_list)
    alice = list.shared_participants.create!(display_name: "Alice")
    list.shared_participants.create!(display_name: "Bob")
    alice.accept! # Bob still pending
    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 4
    )

    assert_raises(ArmyList::LockConflictError) { list.submit! }
  end

  test "submit! on shared list succeeds when all participants accepted" do
    list = army_lists(:shared_list)
    alice = list.shared_participants.create!(display_name: "Alice")
    bob = list.shared_participants.create!(display_name: "Bob")
    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 4
    )
    alice.accept!
    bob.accept!

    list.submit!
    assert list.reload.submitted?
    assert_equal 1, list.miniature_locks.count
  end
end
