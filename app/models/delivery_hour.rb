# == Schema Information
#
# Table name: delivery_hours
#
#  id          :integer          not null, primary key
#  supplier_id :integer          not null
#  wday        :integer          not null
#  off         :boolean          default(FALSE), not null
#  schedule_id :integer
#  starts_at   :string(255)
#  ends_at     :string(255)
#
# Indexes
#
#  index_delivery_hours_on_supplier_id           (supplier_id)
#  index_delivery_hours_on_supplier_id_and_wday  (supplier_id,wday) UNIQUE
#

class DeliveryHour < ActiveRecord::Base
  has_paper_trail ignore: %i[schedule_id supplier_id]

  belongs_to :supplier

  validates :starts_at, presence: true,
                        format: { with: CustomValidators::Time.clock_validator }
  validates :ends_at, presence: true,
                      format: { with: CustomValidators::Time.clock_validator },
                      delivery_hours: true

  validates :wday, presence: true, uniqueness: { scope: :supplier_id }

  scope :ordered, -> { order('wday') }

  def hours
    "#{starts_at} - #{ends_at}"
  end

  def closed?
    starts_at == ends_at
  end

  def starts_at_trimmed
    trim_leading_zero(starts_at)
  end

  def ends_at_trimmed
    trim_leading_zero(ends_at)
  end

  private

  def trim_leading_zero(to_trim)
    to_trim[0] == '0' ? to_trim[1..] : to_trim
  end
end
