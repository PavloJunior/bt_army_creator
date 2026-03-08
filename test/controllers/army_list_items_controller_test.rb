require "test_helper"

class ArmyListItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:upcoming_event)
    @army_list = army_lists(:draft_list)
    @variant = variants(:atlas_d)
    @miniature = miniatures(:atlas_mini)

    @item = @army_list.army_list_items.create!(
      miniature: @miniature,
      variant: @variant,
      skill: 4
    )

    # Set ownership cookie using same pattern as sign_in_as
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:army_list_ids] = [ @army_list.id ]
      cookies["army_list_ids"] = cookie_jar[:army_list_ids]
    end
  end

  test "update changes skill level" do
    patch event_army_list_army_list_item_path(@event, @army_list, @item),
      params: { army_list_item: { skill: 2 } },
      as: :turbo_stream

    assert_response :success
    assert_equal 2, @item.reload.skill
  end

  test "update rejects invalid skill" do
    patch event_army_list_army_list_item_path(@event, @army_list, @item),
      params: { army_list_item: { skill: 10 } },
      as: :turbo_stream

    assert_response :success
    assert_equal 4, @item.reload.skill
  end

  test "update enqueues FetchVariantCardJob when card is missing" do
    assert_enqueued_with(job: FetchVariantCardJob, args: [ @variant.id, { skill: 3 } ]) do
      patch event_army_list_army_list_item_path(@event, @army_list, @item),
        params: { army_list_item: { skill: 3 } },
        as: :turbo_stream
    end
  end

  test "update does not enqueue job when card already exists" do
    card = VariantCard.create!(variant: @variant, skill: 2)
    card.image.attach(
      io: StringIO.new("image data"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )

    assert_no_enqueued_jobs(only: FetchVariantCardJob) do
      patch event_army_list_army_list_item_path(@event, @army_list, @item),
        params: { army_list_item: { skill: 2 } },
        as: :turbo_stream
    end
  end

  test "update responds with turbo_stream" do
    patch event_army_list_army_list_item_path(@event, @army_list, @item),
      params: { army_list_item: { skill: 3 } },
      as: :turbo_stream

    assert_response :success
    assert_includes response.content_type, "turbo-stream"
  end
end
