# == Schema Information
#
# Table name: product_properties
#
#  id           :integer          not null, primary key
#  product_id   :integer          not null
#  property_id  :integer          not null
#  position     :integer
#  description  :string(255)      not null
#  product_type :string(255)      default("Product")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_product_properties_on_shared_attributes  (product_id,product_type,property_id)
#

class ProductProperty < ActiveRecord::Base
  require 'data_cleaners'

  DESCRIPTION_BLACKLIST = ['no', 'n/a', '0', '', nil].freeze

  belongs_to :product, polymorphic: true
  belongs_to :property

  auto_strip_attributes :description, squish: true

  validates :product_id, uniqueness: { scope: %i[property_id product_type] }
  validates :property, presence: true
  validates :product, presence: true

  # TODO: A better behavior may be just not to save vs. causing a validation error.
  validate :description_not_blacklisted

  scope :visible, lambda {
    joins(:property).where('properties.active = true')
  }

  before_save :clean_description
  before_save :clean_country

  delegate :display_name, to: :property, allow_nil: true, prefix: false

  def clean_country
    self.description = DataCleaners::Cleaner::Country.clean(description) if description_changed? && property.identifing_name == 'country'
    !description.nil?
  end

  def clean_description(force = false)
    if (description_changed? || force) && (property.identifing_name == 'alcohol')
      # this beautiful monster replaces the first instance of a float with its
      # rounded self. This is to account for "90 proof" as well as "90.999%"
      description.to_s.gsub!(/#{description.to_f}/, description.to_f.round(2).to_s)
    end
  end

  #-----------------------------------------------------
  # Class methods
  #-----------------------------------------------------

  #-----------------------------------------------------
  # Instance methods
  #-----------------------------------------------------

  def update_description(item_volume)
    update_attribute :description, DataCleaners::Parser::Volume.clean(item_volume)
  end

  def description_not_blacklisted
    errors.add(:description, "value is blacklisted. #{property&.display_name}: #{description}") if DESCRIPTION_BLACKLIST.include?(String(description).downcase)
  end
end
