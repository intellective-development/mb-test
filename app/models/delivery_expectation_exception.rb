# == Schema Information
#
# Table name: delivery_expectation_exceptions
#
#  id                           :integer          not null, primary key
#  shipping_method_id           :integer
#  maximum_delivery_expectation :integer          default(60)
#  delivery_expectation         :string
#  start_date                   :datetime         not null
#  end_date                     :datetime         not null
#
# Indexes
#
#  index_delivery_expectation_exceptions_on_shipping_method_id  (shipping_method_id)
#

class DeliveryExpectationException < ActiveRecord::Base
  include FormatDateTime

  belongs_to :shipping_method, touch: true, inverse_of: :delivery_expectation_exceptions

  scope :active, ->(origin = Time.zone.now) { where('start_date < ? and end_date > ?', origin, origin) }
  # scope :active, ->(origin = Time.zone.now) { where("to_date_time(start_date, 'MM/DD/YYYY hh:mm:ss') < ? and to_date_time(end_date, 'MM/DD/YYYY') > ?", origin) }

  validates :delivery_expectation, presence: true
end
