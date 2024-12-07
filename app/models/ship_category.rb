# == Schema Information
#
# Table name: ship_categories
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  pim_name   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ShipCategory < ActiveRecord::Base
  NATIONAL_CATEGORIES = ['Other Products', 'Non-Alcohol', 'Merchandise'].freeze

  has_paper_trail

  has_one :no_ship_state, dependent: nil
  has_many :supplier_ship_states, dependent: nil

  validates :name, :pim_name, presence: true

  before_destroy :can_be_deleted?
  validate :can_be_deleted, on: %i[destroy delete]

  scope :by_name, ->(name) { where('name ILIKE :name OR pim_name ILIKE :name', name: "%#{name}%") }
  scope :alcoholic, -> { where.not(pim_name: NATIONAL_CATEGORIES) }

  def can_be_deleted?
    return if created_less_than_an_hour_ago?

    errors.add(:base, message: "Can't delete an ship category created more than 1 hour ago")
    throw(:abort)
  end

  def created_less_than_an_hour_ago?
    created_at >= 1.hour.ago
  end
end
