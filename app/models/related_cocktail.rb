# == Schema Information
#
# Table name: related_cocktails
#
#  id                  :integer          not null, primary key
#  cocktail_id         :integer
#  related_cocktail_id :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class RelatedCocktail < ActiveRecord::Base
  belongs_to :cocktail
  belongs_to :related_cocktail, class_name: 'Cocktail'
end
