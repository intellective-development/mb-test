# == Schema Information
#
# Table name: supplier_holidays
#
#  id          :integer          not null, primary key
#  holiday_id  :integer
#  supplier_id :integer
#
# Indexes
#
#  index_supplier_holidays_on_holiday_id   (holiday_id)
#  index_supplier_holidays_on_supplier_id  (supplier_id)
#

class SupplierHoliday < ActiveRecord::Base
  include Wisper::Publisher

  has_paper_trail

  belongs_to :holiday
  belongs_to :supplier

  after_create :publish_supplier_holiday_created

  def publish_supplier_holiday_created
    broadcast(:supplier_holiday_created, self)
  end

  # If a shipment is scheduled for a newly created holiday then we want to
  # nudge it into the exception state.
  def check_scheduled_shipments
    date = Date.parse(holiday.date)

    supplier.shipments.where(state: %w[paid scheduled])
            .where('scheduled_for >= ?', date.beginning_of_day).where('scheduled_for <= ?', date.end_of_day)
            .find_each do |shipment|
      shipment.transition_to!(:exception, exception_metadata)
    end
  end

  private

  def exception_metadata
    {
      type: 'Supplier Holiday',
      description: "#{supplier.name} was placed on holiday."
    }
  end
end
