class Chassis < ApplicationRecord
  has_many :variants, dependent: :destroy
  has_many :miniatures, dependent: :restrict_with_error
  has_many :sync_attempts, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  def sibling_chassis
    return Chassis.none if mini_group_id.blank?
    Chassis.where(mini_group_id: mini_group_id).where.not(id: id)
  end

  def group_chassis
    return Chassis.where(id: id) if mini_group_id.blank?
    Chassis.where(mini_group_id: mini_group_id)
  end

  def group_chassis_ids
    @group_chassis_ids ||= group_chassis.pluck(:id)
  end

  def miniatures_pool
    Miniature.where(chassis_id: group_chassis_ids)
  end

  def shared_minis?
    mini_group_id.present? && sibling_chassis.exists?
  end
end
