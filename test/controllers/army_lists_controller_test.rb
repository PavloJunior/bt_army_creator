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

  private

  def set_army_list_cookie(ids)
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:army_list_ids] = ids
      cookies["army_list_ids"] = cookie_jar[:army_list_ids]
    end
  end
end
