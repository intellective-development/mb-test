# == Schema Information
#
# Table name: ingredients
#
#  id          :integer          not null, primary key
#  name        :text
#  product     :text
#  qty         :text
#  cocktail_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_ingredients_on_cocktail_id  (cocktail_id)
#

class Ingredient < ActiveRecord::Base
  belongs_to :cocktail
end
