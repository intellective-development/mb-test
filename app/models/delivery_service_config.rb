# == Schema Information
#
# Table name: delivery_service_configs
#
#  id                  :integer          not null, primary key
#  name                :string
#  delivery_service_id :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_delivery_service_configs_on_delivery_service_id  (delivery_service_id)
#  index_delivery_service_configs_on_name                 (name)
#
# Foreign Keys
#
#  fk_rails_...  (delivery_service_id => delivery_services.id)
#

class DeliveryServiceConfig < ActiveRecord::Base
  has_one :delivery_services
end
