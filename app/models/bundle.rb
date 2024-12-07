# == Schema Information
#
# Table name: bundles
#
#  id           :integer          not null, primary key
#  type         :string(100)
#  description  :text
#  category     :string
#  starts_at    :datetime
#  ends_at      :datetime
#  user_id      :integer
#  cocktail_id  :integer
#  source_type  :string
#  source_id    :integer
#  sponsor_type :string(64)       default("Internal")
#  sponsor_name :string           default("Minibar")
#  sponsor_id   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_bundles_on_cocktail_id                (cocktail_id)
#  index_bundles_on_source_type_and_source_id  (source_type,source_id)
#  index_bundles_on_user_id                    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (cocktail_id => cocktails.id)
#  fk_rails_...  (user_id => users.id)
#

class Bundle < ActiveRecord::Base
  COCKTAIL_CATEGORY = 'cocktail'.freeze
  CART_CATEGORY = 'cart'.freeze
  BUNDLE_CATEGORIES = [CART_CATEGORY, COCKTAIL_CATEGORY].freeze

  belongs_to :user
  belongs_to :cocktail
  belongs_to :source, polymorphic: true
  belongs_to :sponsor, polymorphic: true

  has_many :bundle_items, dependent: :destroy

  before_validation :set_source, if: :source_attributes_changed?
  before_validation :set_sponsor, if: :sponsor_attributes_changed?

  accepts_nested_attributes_for :source
  accepts_nested_attributes_for :bundle_items

  validates :user, :source, presence: true
  validates :starts_at, :ends_at, presence: true
  validate :validate_source
  before_save :set_category

  #----------------------------------------------------------------------
  # Scopes
  #----------------------------------------------------------------------
  scope :for_type_and_ids, ->(source_type, source_ids) { where(source_type: source_type, source_id: source_ids) }
  scope :for_types, ->(source_types) { where(source_type: source_types) }
  scope :active, -> { where('starts_at <= now() AND ends_at >= now()') }

  #----------------------------------------------------------------------
  # Instance Methods
  #----------------------------------------------------------------------
  def source_attributes_changed?
    source_type_changed?
  end

  def sponsor_attributes_changed?
    sponsor_type_changed?
  end

  def set_source
    return unless source_type && source_id

    source_class = source_type.classify.constantize
    self.source = source_class.friendly.find(source_id)
  end

  def set_sponsor
    return unless sponsor_type && sponsor_key

    sponsor_class_name = sponsor_type.classify
    return unless Object.const_defined?(sponsor_class_name)

    self.sponsor = sponsor_class_name.constantize.friendly.find(sponsor_key)
  end

  def self.admin_grid(_params = {}, _active_state = nil)
    Bundle
  end

  # private

  def set_category
    self.category = if cocktail.present?
                      COCKTAIL_CATEGORY
                    else
                      CART_CATEGORY
                    end
  end

  def validate_source
    existing_bundle = Bundle.active.where(source_type: source_type, source_id: source_id)
    if !existing_bundle.empty? && id != existing_bundle.first.id
      errors.add :source_id, 'There is already a bundle with the same source'
      false
    end
  end
end
