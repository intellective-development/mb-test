# frozen_string_literal: true

# == Schema Information
#
# Table name: bar_os_delivery_breaks
#
#  shipping_method_id :integer
#  supplier_id        :integer
#  starts_at          :datetime
#  ends_at            :datetime
#  resource_type      :text
#  resource_id        :integer
#  timezone           :string(255)
#
# Indexes
#
#  index_bar_os_delivery_breaks_on_ends_at                        (ends_at)
#  index_bar_os_delivery_breaks_on_resource_type_and_resource_id  (resource_type,resource_id)
#  index_bar_os_delivery_breaks_on_row                            (shipping_method_id,starts_at,ends_at,resource_type,resource_id) UNIQUE
#  index_bar_os_delivery_breaks_on_shipping_method_id             (shipping_method_id)
#  index_bar_os_delivery_breaks_on_starts_at                      (starts_at)
#  index_bar_os_delivery_breaks_on_supplier_id                    (supplier_id)
#  index_bar_os_delivery_breaks_on_timezone                       (timezone)
#

# BarOS::DeliveryBreak

# rubocop:disable Style/ClassAndModuleChildren
class BarOS::DeliveryBreak < ApplicationRecord
  belongs_to :shipping_method
  belongs_to :supplier
  belongs_to :resource, polymorphic: true

  scope :by_time, lambda { |time = Time.zone.now|
    where(<<-SQL.squish, time: time)
      :time BETWEEN "#{table_name}"."starts_at" AND "#{table_name}"."ends_at"
    SQL
  }

  def readonly?
    true
  end

  class << self
    def refresh
      Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
