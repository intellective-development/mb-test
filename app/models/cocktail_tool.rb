# == Schema Information
#
# Table name: cocktail_tools
#
#  id          :integer          not null, primary key
#  cocktail_id :integer
#  tool_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class CocktailTool < ActiveRecord::Base
  belongs_to :cocktail
  belongs_to :tool
end
