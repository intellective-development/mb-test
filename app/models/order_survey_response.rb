# == Schema Information
#
# Table name: order_survey_responses
#
#  id                     :integer          not null, primary key
#  order_survey_id        :integer
#  order_survey_reason_id :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_order_survey_responses_on_order_survey_id  (order_survey_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_survey_id => order_surveys.id)
#  fk_rails_...  (order_survey_reason_id => order_survey_reasons.id)
#

class OrderSurveyResponse < ActiveRecord::Base
  belongs_to :order_survey
  belongs_to :order_survey_reason
end
