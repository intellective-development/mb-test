# == Schema Information
#
# Table name: delivery_service_logs
#
#  id                   :integer          not null, primary key
#  key                  :string
#  order_id             :string
#  store_id             :string
#  event                :string
#  event_date           :string
#  order_status         :string
#  payment_status       :string
#  payment_error_reason :string
#  driver               :json
#  point                :json
#  new_order            :json
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  delivery_service_id  :integer
#
# Foreign Keys
#
#  fk_rails_...  (delivery_service_id => delivery_services.id)
#

class DeliveryServiceLog < ActiveRecord::Base
end
