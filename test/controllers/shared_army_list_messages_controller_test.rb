require "test_helper"

class SharedArmyListMessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:shared_event)
    @list = army_lists(:shared_list)
    @alice = @list.shared_participants.create!(display_name: "Alice")
    @bob = @list.shared_participants.create!(display_name: "Bob")
  end

  # =========================================================================
  # create
  # =========================================================================

  test "create posts a message attributed to the current participant" do
    set_participant_cookie([ @alice.token ])

    assert_difference "SharedArmyListMessage.count", 1 do
      post event_shared_army_list_shared_messages_path(@event),
           params: { shared_army_list_message: { body: "Hello team" } }
    end

    msg = SharedArmyListMessage.order(:id).last
    assert_equal "Hello team", msg.body
    assert_equal @alice.id, msg.participant_id
    assert_equal "Alice", msg.sender_name
  end

  test "create without a participant cookie is refused" do
    assert_no_difference "SharedArmyListMessage.count" do
      post event_shared_army_list_shared_messages_path(@event),
           params: { shared_army_list_message: { body: "intruder" } }
    end
  end

  test "create rejects empty body" do
    set_participant_cookie([ @alice.token ])

    assert_no_difference "SharedArmyListMessage.count" do
      post event_shared_army_list_shared_messages_path(@event),
           params: { shared_army_list_message: { body: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "create rejects body over 2000 chars" do
    set_participant_cookie([ @alice.token ])

    assert_no_difference "SharedArmyListMessage.count" do
      post event_shared_army_list_shared_messages_path(@event),
           params: { shared_army_list_message: { body: "x" * 2001 } }
    end

    assert_response :unprocessable_entity
  end

  test "create on a non-shared event is refused" do
    plain = events(:upcoming_event)
    set_participant_cookie([ @alice.token ])

    assert_no_difference "SharedArmyListMessage.count" do
      post event_shared_army_list_shared_messages_path(plain),
           params: { shared_army_list_message: { body: "wrong event" } }
    end
  end

  # =========================================================================
  # destroy
  # =========================================================================

  test "destroy soft-deletes the participant's own message" do
    msg = @list.shared_messages.create!(
      participant: @alice,
      sender_name: @alice.display_name,
      body: "I should be removed"
    )
    set_participant_cookie([ @alice.token ])

    delete event_shared_army_list_shared_message_path(@event, msg)

    assert_response :success
    msg.reload
    assert msg.deleted?
    assert_equal "", msg.body
  end

  test "destroy refused for someone else's message" do
    msg = @list.shared_messages.create!(
      participant: @bob,
      sender_name: @bob.display_name,
      body: "Bob's secret"
    )
    set_participant_cookie([ @alice.token ])

    delete event_shared_army_list_shared_message_path(@event, msg)

    assert_response :forbidden
    assert_not msg.reload.deleted?
  end

  test "destroy refused without a participant cookie" do
    msg = @list.shared_messages.create!(
      participant: @alice,
      sender_name: @alice.display_name,
      body: "untouchable"
    )

    delete event_shared_army_list_shared_message_path(@event, msg)

    assert_response :forbidden
    assert_not msg.reload.deleted?
  end

  private

  def set_participant_cookie(tokens)
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:shared_participant_tokens] = tokens
      cookies["shared_participant_tokens"] = cookie_jar[:shared_participant_tokens]
    end
  end
end
