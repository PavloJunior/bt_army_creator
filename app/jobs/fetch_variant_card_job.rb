class FetchVariantCardJob < ApplicationJob
  queue_as :default
  retry_on MulClient::ApiError, wait: :polynomially_longer, attempts: 5 do |job, error|
    # Final failure after all retries exhausted — increment counter so sync can complete
    _variant_id, options = job.arguments
    sync_attempt_id = options&.dig(:sync_attempt_id)
    if sync_attempt_id
      sync_attempt = SyncAttempt.find_by(id: sync_attempt_id)
      if sync_attempt
        sync_attempt.append_error("Card #{_variant_id} (gave up): #{error.message}")
        sync_attempt.increment!(:cards_synced)
        sync_attempt.check_completion!
      end
    end
  end

  def perform(variant_id, skill: 4, sync_attempt_id: nil)
    variant = Variant.find(variant_id)
    variant_card = VariantCard.find_or_create_by!(variant: variant, skill: skill)

    unless variant_card.image.attached?
      data = MulClient.fetch_card_image(variant.mul_id, skill: skill)

      variant_card.image.attach(
        io: StringIO.new(data[:body]),
        filename: "#{variant.mul_id}_skill#{skill}.jpg",
        content_type: data[:content_type]
      )
    end

    if sync_attempt_id
      sync_attempt = SyncAttempt.find_by(id: sync_attempt_id)
      if sync_attempt
        sync_attempt.increment!(:cards_synced)
        sync_attempt.check_completion!
      end
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
