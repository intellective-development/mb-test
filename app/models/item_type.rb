# frozen_string_literal: true

# == Schema Information
#
# Table name: item_types
#
#  id   :integer          not null, primary key
#  name :string(255)
#

# TODO: JM: This model serves no purpose except to bloat the code, make it fragile and irritate me!
class ItemType < ActiveRecord::Base
  has_many :cart_items

  SHOPPING_CART   = 'shopping_cart'
  SAVE_FOR_LATER  = 'save_for_later'
  PURCHASED       = 'purchased'
  NAMES = [SHOPPING_CART, SAVE_FOR_LATER, PURCHASED].freeze

  SHOPPING_CART_ID   = 1
  SAVE_FOR_LATER_ID  = 2
  PURCHASED_ID       = 3

  validates :name, presence: true, length: { maximum: 55 }
end
