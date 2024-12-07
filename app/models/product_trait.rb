# == Schema Information
#
# Table name: product_traits
#
#  id                   :integer          not null, primary key
#  product_id           :integer
#  engraving_location   :string
#  pre_sale_expectation :string
#  weight               :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  ship_category        :string
#  title                :string
#  main_image_url       :string
#  traits               :jsonb
#
# Indexes
#
#  index_product_traits_on_product_id  (product_id)
#

class ProductTrait < ActiveRecord::Base
  belongs_to :product
  belongs_to :ship_category_model, class_name: 'ShipCategory', foreign_key: :ship_category, primary_key: :pim_name # rubocop:todo Rails/InverseOf

  def method_missing(method_name, *args, &block)
    insensitive_hash[method_name.to_s] || super
  end

  def respond_to_missing?(method_name, include_private = false)
    insensitive_hash[method_name.to_s] || super
  end

  def engravable?
    return false if traits.blank?

    traits['Is_Engravable']&.first || false
  end

  def engraving_lines
    return if traits.blank? || traits['Engraving_Lines'].blank?

    [traits['Engraving_Lines'].first.to_i, EngravingOptions::ENGRAVING_LINE_LIMIT].min
  end

  def engraving_lines_character_limit
    return if traits.blank? || traits['Engraving_Lines_Character_Limit'].blank?

    [traits['Engraving_Lines_Character_Limit']&.first.to_i, EngravingOptions::ENGRAVING_LINE_CHARACTER_LIMIT].compact.first
  end

  def engraving_location_options
    return [] if traits.blank? || traits['Engraving_Location_Options'].blank?

    traits['Engraving_Location_Options'].pluck('name')
  end

  private

  def insensitive_hash
    traits.transform_keys(&:downcase)
  end
end
