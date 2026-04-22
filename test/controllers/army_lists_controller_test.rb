require "test_helper"

class ArmyListsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:upcoming_event)
    @draft_list = army_lists(:draft_list)
    @submitted_list = army_lists(:submitted_list)
    @inactive_list = army_lists(:inactive_list)
  end

  # --- Deactivate ---

  test "deactivate transitions submitted list to inactive" do
    @submitted_list.army_list_items.create!(
      miniature: miniatures(:commando_mini),
      variant: variants(:commando_2d),
      skill: 4
    )
    MiniatureLock.create!(miniature: miniatures(:commando_mini), event: @event, army_list: @submitted_list)

    set_army_list_cookie([ @submitted_list.id ])
    patch deactivate_event_army_list_path(@event, @submitted_list)

    assert_redirected_to event_army_list_path(@event, @submitted_list)
    @submitted_list.reload
    assert @submitted_list.inactive?
    assert_equal 0, @submitted_list.miniature_locks.count
  end

  test "deactivate does nothing for draft list" do
    set_army_list_cookie([ @draft_list.id ])
    patch deactivate_event_army_list_path(@event, @draft_list)

    assert_redirected_to event_army_list_path(@event, @draft_list)
    @draft_list.reload
    assert @draft_list.draft?
  end

  test "deactivate requires ownership" do
    patch deactivate_event_army_list_path(@event, @submitted_list)
    assert_redirected_to event_path(@event)
  end

  # --- Reactivate ---

  test "reactivate transitions inactive list to submitted" do
    @inactive_list.army_list_items.create!(
      miniature: miniatures(:commando_mini),
      variant: variants(:commando_2d),
      skill: 4
    )

    set_army_list_cookie([ @inactive_list.id ])
    patch reactivate_event_army_list_path(@event, @inactive_list)

    assert_redirected_to event_army_list_path(@event, @inactive_list)
    @inactive_list.reload
    assert @inactive_list.submitted?
    assert_equal 1, @inactive_list.miniature_locks.count
  end

  test "reactivate fails when miniatures are locked by another list" do
    @inactive_list.army_list_items.create!(
      miniature: miniatures(:commando_mini),
      variant: variants(:commando_2d),
      skill: 4
    )
    # Another list already locked this miniature
    MiniatureLock.create!(miniature: miniatures(:commando_mini), event: @event, army_list: @submitted_list)

    set_army_list_cookie([ @inactive_list.id ])
    patch reactivate_event_army_list_path(@event, @inactive_list)

    assert_redirected_to event_army_list_path(@event, @inactive_list)
    assert flash[:alert].present?
    @inactive_list.reload
    assert @inactive_list.inactive?
  end

  test "reactivate does nothing for draft list" do
    set_army_list_cookie([ @draft_list.id ])
    patch reactivate_event_army_list_path(@event, @draft_list)

    assert_redirected_to event_army_list_path(@event, @draft_list)
    @draft_list.reload
    assert @draft_list.draft?
  end

  test "reactivate requires ownership" do
    patch reactivate_event_army_list_path(@event, @inactive_list)
    assert_redirected_to event_path(@event)
  end

  # --- Completed event guard ---

  test "deactivate blocked on completed event" do
    @event.update!(status: "completed")
    set_army_list_cookie([ @submitted_list.id ])
    patch deactivate_event_army_list_path(@event, @submitted_list)

    assert_redirected_to event_army_list_path(@event, @submitted_list)
    assert flash[:alert].present?
    @submitted_list.reload
    assert @submitted_list.submitted?
  end

  test "reactivate blocked on completed event" do
    @event.update!(status: "completed")
    set_army_list_cookie([ @inactive_list.id ])
    patch reactivate_event_army_list_path(@event, @inactive_list)

    assert_redirected_to event_army_list_path(@event, @inactive_list)
    assert flash[:alert].present?
    @inactive_list.reload
    assert @inactive_list.inactive?
  end

  test "submit blocked on completed event" do
    @event.update!(status: "completed")
    set_army_list_cookie([ @draft_list.id ])
    patch submit_event_army_list_path(@event, @draft_list)

    assert_redirected_to event_army_list_path(@event, @draft_list)
    assert flash[:alert].present?
    @draft_list.reload
    assert @draft_list.draft?
  end

  # --- Create with event_side triggers recalculate ---

  test "creating a list on a themed event side unlocks submitted lists on that side" do
    themed_event = events(:themed_event)
    themed_event.update!(status: "active")
    side = event_sides(:comstar_side)

    # Create and submit a list on the side
    existing_list = ArmyList.create!(event: themed_event, event_side: side, player_name: "Existing Player", status: "draft", tech_base: "inner_sphere")
    existing_list.army_list_items.create!(miniature: miniatures(:atlas_mini), variant: variants(:atlas_d), skill: 4)
    existing_list.submit!
    assert existing_list.reload.submitted?

    # Create a new list on the same side via controller
    post event_army_lists_path(themed_event), params: {
      army_list: { player_name: "New Player", tech_base: "inner_sphere", event_side_id: side.id }
    }

    # The submitted list should be reset to draft
    assert existing_list.reload.draft?
  end

  # --- Deactivate triggers recalculate on themed event ---

  test "deactivating a list on a themed event side unlocks other submitted lists" do
    themed_event = events(:themed_event)
    themed_event.update!(status: "active")
    side = event_sides(:comstar_side)

    list1 = ArmyList.create!(event: themed_event, event_side: side, player_name: "Player 1", status: "draft", tech_base: "inner_sphere")
    list1.army_list_items.create!(miniature: miniatures(:atlas_mini), variant: variants(:atlas_d), skill: 4)
    list1.submit!

    list2 = ArmyList.create!(event: themed_event, event_side: side, player_name: "Player 2", status: "draft", tech_base: "inner_sphere")
    list2.army_list_items.create!(miniature: miniatures(:commando_mini), variant: variants(:commando_2d), skill: 4)
    list2.submit!

    set_army_list_cookie([ list2.id ])
    patch deactivate_event_army_list_path(themed_event, list2)

    assert_redirected_to event_army_list_path(themed_event, list2)
    assert list1.reload.draft?
    assert list2.reload.inactive?
  end

  # --- Toggle faction guard ---

  test "toggle_faction blocked on submitted list" do
    set_army_list_cookie([ @submitted_list.id ])
    patch toggle_faction_event_army_list_path(@event, @submitted_list), params: { faction_mul_id: 1 }

    assert_redirected_to event_army_list_path(@event, @submitted_list)
  end

  test "toggle_faction blocked on inactive list" do
    set_army_list_cookie([ @inactive_list.id ])
    patch toggle_faction_event_army_list_path(@event, @inactive_list), params: { faction_mul_id: 1 }

    assert_redirected_to event_army_list_path(@event, @inactive_list)
  end

  # =========================================================================
  # Shared army list
  # =========================================================================

  test "shared event: new redirects straight to the auto-created shared list" do
    shared_event = events(:shared_event)
    list = shared_event.shared_army_list_record

    get new_event_army_list_path(shared_event)

    assert_redirected_to event_army_list_path(shared_event, list)
  end

  test "shared event: create redirects straight to the auto-created shared list" do
    shared_event = events(:shared_event)
    list = shared_event.shared_army_list_record

    assert_no_difference "ArmyList.count" do
      post event_army_lists_path(shared_event), params: {
        army_list: { player_name: "Noop", tech_base: "mixed" }
      }
    end

    assert_redirected_to event_army_list_path(shared_event, list)
  end

  test "shared list: change_tech_base is refused" do
    shared_event = events(:shared_event)
    list = shared_event.shared_army_list_record
    original = list.tech_base
    alice = list.shared_participants.create!(display_name: "Alice")
    set_participant_cookie([ alice.token ])

    patch change_tech_base_event_army_list_path(shared_event, list),
          params: { tech_base: "clan" }

    assert_redirected_to event_army_list_path(shared_event, list)
    assert_equal original, list.reload.tech_base,
      "shared list tech base must never change via the public endpoint"
  end

  test "shared list: toggle_faction is refused" do
    shared_event = events(:shared_event)
    list = shared_event.shared_army_list_record
    alice = list.shared_participants.create!(display_name: "Alice")
    set_participant_cookie([ alice.token ])

    patch toggle_faction_event_army_list_path(shared_event, list),
          params: { faction_mul_id: 29 }

    assert_redirected_to event_army_list_path(shared_event, list)
    assert_equal 0, list.army_list_factions.count
  end

  test "shared list: clear is refused" do
    shared_event = events(:shared_event)
    list = shared_event.shared_army_list_record
    alice = list.shared_participants.create!(display_name: "Alice")
    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      added_by_participant: alice
    )
    set_participant_cookie([ alice.token ])

    delete clear_event_army_list_path(shared_event, list)

    assert_redirected_to event_army_list_path(shared_event, list)
    assert_equal 1, list.army_list_items.count,
      "shared list items must not be cleared by the public clear action"
  end

  test "shared list: submit is blocked until every participant has accepted" do
    shared_event = events(:shared_event)
    shared_event.update!(status: "active")
    list = shared_event.shared_army_list_record
    alice = list.shared_participants.create!(display_name: "Alice")
    list.shared_participants.create!(display_name: "Bob")
    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      added_by_participant: alice
    )
    alice.accept! # Bob still pending
    set_participant_cookie([ alice.token ])

    patch submit_event_army_list_path(shared_event, list)

    assert_redirected_to event_army_list_path(shared_event, list)
    assert flash[:alert].present?
    assert list.reload.draft?
  end

  test "shared list: submit succeeds when all participants accepted" do
    shared_event = events(:shared_event)
    shared_event.update!(status: "active")
    list = shared_event.shared_army_list_record
    alice = list.shared_participants.create!(display_name: "Alice")
    bob = list.shared_participants.create!(display_name: "Bob")
    list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      added_by_participant: alice
    )
    alice.accept!
    bob.accept!
    set_participant_cookie([ alice.token ])

    patch submit_event_army_list_path(shared_event, list)

    assert_redirected_to event_army_list_path(shared_event, list)
    assert list.reload.submitted?
  end

  test "shared list: non-participant, non-admin cannot submit" do
    shared_event = events(:shared_event)
    shared_event.update!(status: "active")
    list = shared_event.shared_army_list_record
    alice = list.shared_participants.create!(display_name: "Alice")
    alice.accept!

    patch submit_event_army_list_path(shared_event, list)

    assert_redirected_to event_path(shared_event)
    assert list.reload.draft?
  end

  # -------------------------------------------------------------------------
  # clear_mine (shared list: remove only the current participant's items)
  # -------------------------------------------------------------------------

  test "shared list: clear_mine destroys only items added by the current participant" do
    shared_event = events(:shared_event)
    list = shared_event.shared_army_list_record
    alice = list.shared_participants.create!(display_name: "Alice")
    bob = list.shared_participants.create!(display_name: "Bob")

    alice_item = list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      added_by_participant: alice
    )
    bob_item = list.army_list_items.create!(
      miniature: miniatures(:commando_mini),
      variant: variants(:commando_2d),
      added_by_participant: bob
    )

    set_participant_cookie([ alice.token ])
    delete clear_mine_event_army_list_path(shared_event, list)

    assert_redirected_to event_army_list_path(shared_event, list)
    assert_raises(ActiveRecord::RecordNotFound) { alice_item.reload }
    assert bob_item.reload.persisted?
  end

  test "shared list: clear_mine leaves unclaimed items alone" do
    shared_event = events(:shared_event)
    list = shared_event.shared_army_list_record
    alice = list.shared_participants.create!(display_name: "Alice")
    unclaimed_item = list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      added_by_participant: nil
    )

    set_participant_cookie([ alice.token ])
    delete clear_mine_event_army_list_path(shared_event, list)

    assert unclaimed_item.reload.persisted?,
      "unclaimed items should not be touched by clear_mine"
  end

  test "shared list: clear_mine refused without a participant cookie" do
    shared_event = events(:shared_event)
    list = shared_event.shared_army_list_record
    alice = list.shared_participants.create!(display_name: "Alice")
    item = list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      added_by_participant: alice
    )

    delete clear_mine_event_army_list_path(shared_event, list)

    assert_redirected_to event_path(shared_event)
    assert item.reload.persisted?
  end

  test "clear_mine refuses on non-shared lists" do
    set_army_list_cookie([ @draft_list.id ])

    delete clear_mine_event_army_list_path(@event, @draft_list)

    assert_redirected_to event_army_list_path(@event, @draft_list)
  end

  private

  def set_army_list_cookie(ids)
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:army_list_ids] = ids
      cookies["army_list_ids"] = cookie_jar[:army_list_ids]
    end
  end

  def set_participant_cookie(tokens)
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:shared_participant_tokens] = tokens
      cookies["shared_participant_tokens"] = cookie_jar[:shared_participant_tokens]
    end
  end
end
