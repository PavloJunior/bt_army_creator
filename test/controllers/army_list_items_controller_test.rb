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

  test "create adds item with auto-assigned miniature" do
    @item.destroy # free up the atlas mini

    assert_difference("ArmyListItem.count", 1) do
      post event_army_list_army_list_items_path(@event, @army_list),
        params: { army_list_item: { chassis_id: chassis(:atlas).id, variant_id: @variant.id } },
        as: :turbo_stream
    end

    assert_response :success
    item = @army_list.army_list_items.last
    assert_equal @miniature, item.miniature
    assert_equal @variant, item.variant
  end

  test "create returns error when no miniatures available" do
    # atlas_mini is already used in @item from setup
    assert_no_difference("ArmyListItem.count") do
      post event_army_list_army_list_items_path(@event, @army_list),
        params: { army_list_item: { chassis_id: chassis(:atlas).id, variant_id: @variant.id } },
        as: :turbo_stream
    end

    assert_response :success
    assert_includes response.body, "Brak"
  end

  test "create responds with turbo_stream replacing chassis card" do
    @item.destroy

    post event_army_list_army_list_items_path(@event, @army_list),
      params: { army_list_item: { chassis_id: chassis(:atlas).id, variant_id: @variant.id } },
      as: :turbo_stream

    assert_response :success
    assert_includes response.content_type, "turbo-stream"
    assert_includes response.body, "available_chassis_#{chassis(:atlas).id}"
  end

  test "destroy removes item and updates chassis card" do
    delete event_army_list_army_list_item_path(@event, @army_list, @item),
      as: :turbo_stream

    assert_response :success
    assert_raises(ActiveRecord::RecordNotFound) { @item.reload }
    assert_includes response.body, "available_chassis_#{chassis(:atlas).id}"
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

  # Shared miniatures tests

  test "create auto-assigns miniature from shared pool for sibling chassis" do
    gauss = chassis(:schrek_gauss)
    ppc = chassis(:schrek_ppc)
    ppc_variant = variants(:schrek_ppc_standard)

    # schrek_mini_1 and schrek_mini_2 belong to schrek_gauss but should be usable for schrek_ppc via shared pool
    assert_difference("ArmyListItem.count", 1) do
      post event_army_list_army_list_items_path(@event, @army_list),
        params: { army_list_item: { chassis_id: ppc.id, variant_id: ppc_variant.id } },
        as: :turbo_stream
    end

    assert_response :success
    item = @army_list.army_list_items.order(:id).last
    assert_equal ppc_variant, item.variant
    # Miniature should come from the shared pool (owned by gauss chassis)
    assert_includes gauss.miniatures.pluck(:id), item.miniature_id
  end

  test "create turbo stream includes sibling chassis card replacements" do
    ppc = chassis(:schrek_ppc)
    gauss = chassis(:schrek_gauss)
    ppc_variant = variants(:schrek_ppc_standard)

    post event_army_list_army_list_items_path(@event, @army_list),
      params: { army_list_item: { chassis_id: ppc.id, variant_id: ppc_variant.id } },
      as: :turbo_stream

    assert_response :success
    assert_includes response.body, "available_chassis_#{ppc.id}"
    assert_includes response.body, "available_chassis_#{gauss.id}"
  end

  test "destroy turbo stream includes sibling chassis card replacements" do
    ppc = chassis(:schrek_ppc)
    gauss = chassis(:schrek_gauss)
    ppc_variant = variants(:schrek_ppc_standard)

    item = @army_list.army_list_items.create!(
      miniature: miniatures(:schrek_mini_1),
      variant: ppc_variant
    )

    delete event_army_list_army_list_item_path(@event, @army_list, item),
      as: :turbo_stream

    assert_response :success
    assert_includes response.body, "available_chassis_#{ppc.id}"
    assert_includes response.body, "available_chassis_#{gauss.id}"
  end

  test "create rejects variant with wrong tech base" do
    @item.destroy
    @army_list.update!(tech_base: "clan")

    assert_no_difference("ArmyListItem.count") do
      post event_army_list_army_list_items_path(@event, @army_list),
        params: { army_list_item: { chassis_id: chassis(:atlas).id, variant_id: @variant.id } },
        as: :turbo_stream
    end

    assert_response :success
  end
end
