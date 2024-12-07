# == Schema Information
#
# Table name: activation_logs
#
#  id             :integer          not null, primary key
#  product_id     :integer
#  score          :integer
#  log_attributes :json
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class ActivationLog < ActiveRecord::Base
end
