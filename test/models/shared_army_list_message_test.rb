require "test_helper"

class SharedArmyListMessageTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  setup do
    @list = army_lists(:shared_list)
    @participant = @list.shared_participants.create!(display_name: "Alice")
  end

  test "requires body" do
    msg = @list.shared_messages.build(sender_name: "Alice", body: nil)
    assert_not msg.valid?
    assert msg.errors[:body].any?
  end

  test "requires sender_name" do
    msg = @list.shared_messages.build(sender_name: nil, body: "hi")
    assert_not msg.valid?
    assert msg.errors[:sender_name].any?
  end

  test "body length capped at 2000" do
    msg = @list.shared_messages.build(sender_name: "Alice", body: "x" * 2001)
    assert_not msg.valid?
    assert msg.errors[:body].any?
  end

  test "valid with participant and body" do
    msg = @list.shared_messages.build(
      sender_name: @participant.display_name,
      participant: @participant,
      body: "hello"
    )
    assert msg.valid?
    assert msg.save
  end

  test "valid with no participant (admin message)" do
    msg = @list.shared_messages.build(sender_name: "Admin", body: "hello")
    assert msg.valid?
    assert msg.save
  end

  test "soft_delete! sets deleted_at and blanks the body" do
    msg = @list.shared_messages.create!(
      sender_name: @participant.display_name,
      participant: @participant,
      body: "secret"
    )
    msg.soft_delete!
    assert msg.deleted?
    assert_not_nil msg.deleted_at
    assert_equal "", msg.body
  end

  test "visible scope excludes soft-deleted messages and orders by created_at" do
    older = @list.shared_messages.create!(sender_name: "Alice", body: "first")
    newer = @list.shared_messages.create!(sender_name: "Alice", body: "second")
    hidden = @list.shared_messages.create!(sender_name: "Alice", body: "third")
    hidden.soft_delete!

    visible = @list.shared_messages.visible.to_a
    assert_includes visible, older
    assert_includes visible, newer
    assert_not_includes visible, hidden
    assert_equal [ older.id, newer.id ], visible.map(&:id)
  end

  test "creating a message broadcasts append to the shared stream" do
    assert_broadcasts "shared_army_list_#{@list.id}", 1 do
      @list.shared_messages.create!(
        participant: @participant,
        sender_name: @participant.display_name,
        body: "hello"
      )
    end
  end

  test "soft-deleting a message broadcasts a replace" do
    msg = @list.shared_messages.create!(
      participant: @participant,
      sender_name: @participant.display_name,
      body: "to delete"
    )

    assert_broadcasts "shared_army_list_#{@list.id}", 1 do
      msg.soft_delete!
    end
  end
end
