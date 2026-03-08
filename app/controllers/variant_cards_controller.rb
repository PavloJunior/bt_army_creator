class VariantCardsController < ApplicationController
  def show
    variant = Variant.find(params[:id])
    skill = params[:skill].present? ? params[:skill].to_i : 4

    variant_card = VariantCard.find_by(variant: variant, skill: skill)

    if variant_card&.image&.attached?
      redirect_to rails_blob_path(variant_card.image, disposition: "inline"), allow_other_host: true
    else
      FetchVariantCardJob.perform_later(variant.id, skill: skill)
      head :not_found
    end
  end
end
