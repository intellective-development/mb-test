# == Schema Information
#
# Table name: delivery_services
#
#  id                    :integer          not null, primary key
#  name                  :string
#  email                 :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  minimal_delivery_time :integer
#

class DeliveryService < ActiveRecord::Base
  has_many :suppliers
end
