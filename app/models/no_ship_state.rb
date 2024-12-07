# == Schema Information
#
# Table name: no_ship_states
#
#  id               :integer          not null, primary key
#  ship_category_id :integer
#  states           :json
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_no_ship_states_on_ship_category_id  (ship_category_id) UNIQUE
#
class NoShipState < ActiveRecord::Base
  belongs_to :ship_category

  validates :ship_category_id, uniqueness: true

  has_paper_trail ignore: %i[created_at updated_at]
end
