require "test_helper"

class FetchVariantCardJobTest < ActiveJob::TestCase
  setup do
    @variant = variants(:commando_2d)
    @fake_image_data = {
      body: file_fixture("test_card.jpg").read,
      content_type: "image/jpeg"
    }
  end

  test "fetches card image and attaches to variant_card" do
    stub_mul_client do
      FetchVariantCardJob.perform_now(@variant.id, skill: 4)
    end

    card = VariantCard.find_by(variant: @variant, skill: 4)
    assert card.present?
    assert card.image.attached?
    assert_equal "image/jpeg", card.image.content_type
  end

  test "creates new variant_card record if none exists" do
    assert_nil VariantCard.find_by(variant: @variant, skill: 2)

    stub_mul_client do
      FetchVariantCardJob.perform_now(@variant.id, skill: 2)
    end

    card = VariantCard.find_by(variant: @variant, skill: 2)
    assert card.present?
    assert card.image.attached?
  end

  test "skips fetch if card already has image attached" do
    card = VariantCard.create!(variant: @variant, skill: 3)
    card.image.attach(
      io: StringIO.new("existing"),
      filename: "existing.jpg",
      content_type: "image/jpeg"
    )

    called = false
    original = MulClient.method(:fetch_card_image)
    MulClient.define_singleton_method(:fetch_card_image) { |*args, **kwargs| called = true; @fake_image_data }

    begin
      FetchVariantCardJob.perform_now(@variant.id, skill: 3)
    ensure
      MulClient.define_singleton_method(:fetch_card_image, original)
    end

    assert_not called, "Should not call MulClient when image already attached"
  end

  test "defaults to skill 4" do
    stub_mul_client do
      FetchVariantCardJob.perform_now(@variant.id)
    end

    card = VariantCard.find_by(variant: @variant, skill: 4)
    assert card.present?
    assert card.image.attached?
  end

  test "increments sync_attempt cards_synced when sync_attempt_id provided" do
    sync_attempt = SyncAttempt.create!(
      chassis: @variant.chassis,
      status: "running",
      cards_total: 1,
      cards_synced: 0,
      factions_total: 0,
      factions_synced: 0,
      started_at: Time.current
    )

    stub_mul_client do
      FetchVariantCardJob.perform_now(@variant.id, skill: 4, sync_attempt_id: sync_attempt.id)
    end

    assert_equal 1, sync_attempt.reload.cards_synced
  end

  test "works without sync_attempt_id" do
    stub_mul_client do
      FetchVariantCardJob.perform_now(@variant.id, skill: 4)
    end

    card = VariantCard.find_by(variant: @variant, skill: 4)
    assert card.present?
  end

  private

  def stub_mul_client(&block)
    data = @fake_image_data
    original = MulClient.method(:fetch_card_image)
    MulClient.define_singleton_method(:fetch_card_image) { |*args, **kwargs| data }
    yield
  ensure
    MulClient.define_singleton_method(:fetch_card_image, original)
  end
end
