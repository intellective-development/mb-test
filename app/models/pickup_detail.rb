# == Schema Information
#
# Table name: pickup_details
#
#  id                        :integer          not null, primary key
#  name                      :string           not null
#  phone                     :string           not null
#  doorkeeper_application_id :integer
#  user_id                   :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_pickup_details_on_doorkeeper_application_id  (doorkeeper_application_id)
#  index_pickup_details_on_user_id                    (user_id)
#

class PickupDetail < ActiveRecord::Base
  phony_normalize :phone, default_country_code: 'US'

  belongs_to :doorkeeper_application, class_name: 'Doorkeeper::Application'
  has_many :orders
end
