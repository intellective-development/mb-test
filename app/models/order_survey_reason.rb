# == Schema Information
#
# Table name: order_survey_reasons
#
#  id          :integer          not null, primary key
#  name        :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  active      :boolean          default(TRUE)
#

class OrderSurveyReason < ActiveRecord::Base
  scope :active, -> { where(active: true) }
end
