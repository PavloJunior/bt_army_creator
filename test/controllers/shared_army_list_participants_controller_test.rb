require "test_helper"

class SharedArmyListParticipantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:shared_event)
    @list = army_lists(:shared_list)
  end

  # =========================================================================
  # create (join)
  # =========================================================================

  test "join creates a participant, sets the cookie, and redirects to the list" do
    assert_difference "SharedArmyListParticipant.count", 1 do
      post event_shared_army_list_shared_participants_path(@event),
           params: { shared_army_list_participant: { display_name: "Alice" } }
    end

    assert_redirected_to event_army_list_path(@event, @list)

    participant = SharedArmyListParticipant.order(:id).last
    assert_equal "Alice", participant.display_name
    assert_equal @list, participant.army_list
    assert cookies["shared_participant_tokens"].present?,
      "join must set the shared_participant_tokens cookie"
  end

  test "join rejects a duplicate (case-insensitive) active display_name" do
    @list.shared_participants.create!(display_name: "Alice")

    assert_no_difference "SharedArmyListParticipant.count" do
      post event_shared_army_list_shared_participants_path(@event),
           params: { shared_army_list_participant: { display_name: "alice" } }
    end

    assert_response :unprocessable_entity
  end

  test "join allows reusing the name of a participant who has left" do
    alice = @list.shared_participants.create!(display_name: "Alice")
    alice.leave!

    assert_difference "SharedArmyListParticipant.count", 1 do
      post event_shared_army_list_shared_participants_path(@event),
           params: { shared_army_list_participant: { display_name: "alice" } }
    end
  end

  test "join on a non-shared event is refused" do
    plain = events(:upcoming_event)

    assert_no_difference "SharedArmyListParticipant.count" do
      post event_shared_army_list_shared_participants_path(plain),
           params: { shared_army_list_participant: { display_name: "Alice" } }
    end

    assert_redirected_to event_path(plain)
  end

  test "joining while already a participant does not create a duplicate" do
    alice = @list.shared_participants.create!(display_name: "Alice")
    set_participant_cookie([ alice.token ])

    assert_no_difference "SharedArmyListParticipant.count" do
      post event_shared_army_list_shared_participants_path(@event),
           params: { shared_army_list_participant: { display_name: "Alice" } }
    end

    assert_redirected_to event_army_list_path(@event, @list)
  end

  # =========================================================================
  # accept / unaccept
  # =========================================================================

  test "accept sets accepted_at for the current participant" do
    alice = @list.shared_participants.create!(display_name: "Alice")
    set_participant_cookie([ alice.token ])

    patch accept_event_shared_army_list_shared_participant_path(@event, alice)

    assert_redirected_to event_army_list_path(@event, @list)
    assert_not_nil alice.reload.accepted_at
  end

  test "accept via turbo_stream replaces the self-acceptance button" do
    alice = @list.shared_participants.create!(display_name: "Alice")
    set_participant_cookie([ alice.token ])

    patch accept_event_shared_army_list_shared_participant_path(@event, alice),
          as: :turbo_stream

    assert_response :success
    assert_includes response.content_type, "turbo-stream"
    assert_includes response.body, "shared_self_acceptance_button"
  end

  test "accept refused when acting on someone else's participant" do
    alice = @list.shared_participants.create!(display_name: "Alice")
    bob = @list.shared_participants.create!(display_name: "Bob")
    set_participant_cookie([ alice.token ])

    patch accept_event_shared_army_list_shared_participant_path(@event, bob)

    assert_response :forbidden
    assert_nil bob.reload.accepted_at
  end

  test "unaccept clears accepted_at for the current participant" do
    alice = @list.shared_participants.create!(display_name: "Alice")
    alice.accept!
    set_participant_cookie([ alice.token ])

    patch unaccept_event_shared_army_list_shared_participant_path(@event, alice)

    assert_redirected_to event_army_list_path(@event, @list)
    assert_nil alice.reload.accepted_at
  end

  # =========================================================================
  # leave
  # =========================================================================

  test "leave soft-deletes the current participant and nullifies their items" do
    alice = @list.shared_participants.create!(display_name: "Alice")
    item = @list.army_list_items.create!(
      miniature: miniatures(:atlas_mini),
      variant: variants(:atlas_d),
      added_by_participant: alice
    )
    set_participant_cookie([ alice.token ])

    patch leave_event_shared_army_list_shared_participant_path(@event, alice)

    assert_redirected_to event_path(@event)
    assert_not_nil alice.reload.left_at
    assert_nil item.reload.added_by_participant_id
  end

  test "leave refused when acting on someone else's participant" do
    alice = @list.shared_participants.create!(display_name: "Alice")
    bob = @list.shared_participants.create!(display_name: "Bob")
    set_participant_cookie([ alice.token ])

    patch leave_event_shared_army_list_shared_participant_path(@event, bob)

    assert_response :forbidden
    assert_nil bob.reload.left_at
  end

  test "any action without a cookie is refused" do
    alice = @list.shared_participants.create!(display_name: "Alice")
    patch accept_event_shared_army_list_shared_participant_path(@event, alice)
    assert_response :forbidden
  end

  private

  def set_participant_cookie(tokens)
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:shared_participant_tokens] = tokens
      cookies["shared_participant_tokens"] = cookie_jar[:shared_participant_tokens]
    end
  end
end
