# == Schema Information
#
# Table name: promotion_filters
#
#  id          :integer          not null, primary key
#  filter      :string
#  description :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class PromotionFilter < ActiveRecord::Base
  has_and_belongs_to_many :promotion
end
