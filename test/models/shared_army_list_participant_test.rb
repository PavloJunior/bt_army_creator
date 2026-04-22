require "test_helper"

class SharedArmyListParticipantTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    @list = army_lists(:shared_list)
  end

  test "requires a display_name" do
    participant = @list.shared_participants.build(display_name: nil)
    assert_not participant.valid?
    assert participant.errors[:display_name].any?
  end

  test "display_name length is capped at 40" do
    participant = @list.shared_participants.build(display_name: "x" * 41)
    assert_not participant.valid?
    assert participant.errors[:display_name].any?
  end

  test "generates a random token on create" do
    participant = @list.shared_participants.create!(display_name: "Alice")
    assert_match(/\A[0-9a-f]{48}\z/, participant.token)
  end

  test "does not regenerate token on update" do
    participant = @list.shared_participants.create!(display_name: "Alice")
    original_token = participant.token
    participant.update!(display_name: "Alice the Great")
    assert_equal original_token, participant.reload.token
  end

  test "display_name is unique per active list, case-insensitive" do
    @list.shared_participants.create!(display_name: "Alice")
    dup = @list.shared_participants.build(display_name: "alice")
    assert_not dup.valid?
    assert dup.errors[:display_name].any? { |m| m.include?("taken") }
  end

  test "display_name of a left participant can be reused" do
    alice = @list.shared_participants.create!(display_name: "Alice")
    alice.leave!

    new_alice = @list.shared_participants.create!(display_name: "alice")
    assert new_alice.persisted?
  end

  test "same display_name can be used across different shared lists" do
    @list.shared_participants.create!(display_name: "Alice")

    other_event = Event.create!(
      name: "Other Shared",
      date: "2026-07-01",
      game_system: "alpha_strike",
      point_cap: 300,
      status: "upcoming",
      shared_army_list: true,
      shared_tech_base: "mixed"
    )

    other_alice = other_event.shared_army_list_record
                              .shared_participants
                              .build(display_name: "Alice")
    assert other_alice.valid?
  end

  test "accept! sets accepted_at" do
    participant = @list.shared_participants.create!(display_name: "Alice")
    freeze_time do
      participant.accept!
      assert_equal Time.current, participant.accepted_at
    end
  end

  test "unaccept! clears accepted_at without firing callbacks" do
    alice = @list.shared_participants.create!(display_name: "Alice")
    bob = @list.shared_participants.create!(display_name: "Bob")
    alice.accept!
    bob.accept!

    alice.unaccept!
    # Bob's acceptance must NOT be cleared by unaccept!
    # (unaccept! is not a membership change, and uses update_columns.)
    assert_nil alice.reload.accepted_at
    assert_not_nil bob.reload.accepted_at
  end

  test "leave! soft-deletes, clears acceptance, and nullifies authored items" do
    alice = @list.shared_participants.create!(display_name: "Alice")
    alice.accept!

    item = @list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      skill: 4,
      added_by_participant: alice
    )

    alice.leave!

    assert_not_nil alice.reload.left_at
    assert_nil alice.accepted_at
    assert_not alice.active?
    assert_nil item.reload.added_by_participant_id,
      "authored items become unclaimed when the adder leaves"
  end

  test "active scope excludes participants with left_at set" do
    alice = @list.shared_participants.create!(display_name: "Alice")
    bob = @list.shared_participants.create!(display_name: "Bob")
    bob.leave!

    active_ids = @list.shared_participants.active.pluck(:id)
    assert_includes active_ids, alice.id
    assert_not_includes active_ids, bob.id
  end

  test "creating a participant broadcasts to the shared list stream" do
    assert_broadcasts "shared_army_list_#{@list.id}", 2 do
      @list.shared_participants.create!(display_name: "Alice")
    end
  end

  test "accepting a participant broadcasts roster + banner" do
    alice = @list.shared_participants.create!(display_name: "Alice")

    assert_broadcasts "shared_army_list_#{@list.id}", 2 do
      alice.accept!
    end
  end

  test "leaving a participant broadcasts roster + banner" do
    alice = @list.shared_participants.create!(display_name: "Alice")

    assert_broadcasts "shared_army_list_#{@list.id}", 2 do
      alice.leave!
    end
  end
end
