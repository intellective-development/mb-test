# == Schema Information
#
# Table name: order_adjustment_reasons
#
#  id                       :integer          not null, primary key
#  name                     :string(255)      not null
#  description              :string(255)
#  owed_to_minibar          :boolean          default(FALSE), not null
#  owed_to_supplier         :boolean          default(FALSE), not null
#  customer_facing_name     :string(255)
#  reporting_type           :integer          default("no_reporting_type_specified")
#  active                   :boolean          default(TRUE), not null
#  cancel                   :boolean          default(TRUE)
#  order_adjustment         :boolean          default(TRUE)
#  marketing_fee_adjustment :boolean          default(FALSE)
#  invoice_display_name     :string
#

class OrderAdjustmentReason < ActiveRecord::Base
  enum reporting_type: {
    no_reporting_type_specified: 0,
    late: 1,
    out_of_stock: 2,
    financial_impact_to_minibar: 3,
    financial_impact_to_supplier: 4
  }

  has_many :order_adjustments, inverse_of: 'reason'

  validates :name, presence: true
  validate :cant_owe_to_both

  scope :active, -> { where(active: true) }
  scope :by_status, ->(status) { where(active: status) }
  scope :by_name,   ->(name)   { where('name ILIKE :name OR description ILIKE :name', name: "%#{name}%") }
  scope :adjustment_reasons, -> { where(order_adjustment: true).order(name: :asc) }
  scope :cancellation_reasons, -> { where(cancel: true).order(name: :asc) }
  scope :financial_impact_reasons, -> { where(reporting_type: %i[financial_impact_to_minibar financial_impact_to_supplier]).order(name: :asc) }

  #--------------------------------
  # Instance methods
  #--------------------------------
  def cant_owe_to_both
    errors.add(:reason, "can't be owed to both Minibar and Supplier") if owed_to_minibar && owed_to_supplier
  end

  def fraud?
    name == 'Fraud'
  end
end
