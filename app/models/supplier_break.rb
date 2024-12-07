# == Schema Information
#
# Table name: delivery_breaks
#
#  id                  :integer          not null, primary key
#  date                :string(20)
#  start_time          :string(20)
#  end_time            :string(20)
#  supplier_id         :integer
#  shipping_method_ids :integer          default([]), is an Array
#  created_at          :datetime
#  updated_at          :datetime
#  apply_to_all        :boolean          default(FALSE), not null
#  type                :string
#  user_id             :integer
#
# Indexes
#
#  index_delivery_breaks_on_shipping_method_ids  (shipping_method_ids) USING gin
#  index_delivery_breaks_on_supplier_id          (supplier_id)
#  index_delivery_breaks_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class SupplierBreak < DeliveryBreak
  belongs_to :user

  before_validation :set_fields_from_period

  attr_accessor :period

  #--------------------------------------
  # Scopes
  #--------------------------------------
  default_scope { where(type: 'SupplierBreak') }
  scope :upcoming, ->(origin = Time.zone.now.beginning_of_day) { where("to_date(date, 'MM/DD/YYYY') >= ?", origin) }

  #-----------------------------------
  # Class methods
  #-----------------------------------

  #--------------------------------------
  # Instance methods
  #--------------------------------------
  def set_fields_from_period
    return unless period

    Time.use_zone(supplier.timezone) do
      now = Time.zone.now
      assign_attributes(date: now.strftime('%m/%d/%Y'), start_time: now.strftime('%l:%M %P'), end_time: (now + period).strftime('%l:%M %P'), shipping_method_ids: supplier.shipping_method_ids)
    end
  end
end
