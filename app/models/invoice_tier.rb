# == Schema Information
#
# Table name: invoice_tiers
#
#  id          :integer          not null, primary key
#  supplier_id :integer
#  start_at    :datetime
#  end_at      :datetime
#  tier_min    :decimal(, )
#  tier_max    :decimal(, )
#  tier_type   :string(255)
#  tier_value  :decimal(, )
#  business_id :integer          default(1)
#
# Indexes
#
#  index_invoice_tiers_on_supplier_id  (supplier_id)
#

class InvoiceTier < ActiveRecord::Base
  has_paper_trail

  belongs_to :supplier, touch: true
  belongs_to :business

  validates :start_at, presence: true
  validates :tier_min, numericality: true, allow_nil: true
  validates :tier_max, numericality: { greater_than: :tier_min }, allow_nil: true
  validates :tier_value, presence: true, numericality: true
  validate :prevent_business_update, on: :update

  before_save :fix_dates

  scope :by_business, ->(business_id) { where(business_id: business_id) }
  scope :for_supplier, ->(supplier_id) { where(supplier_id: supplier_id) }

  def self.active_at(date = Time.zone.now.to_date)
    InvoiceTier.where(['invoice_tiers.start_at <= ? AND (end_at > ? OR end_at IS NULL)', date.to_s(:db), date.to_s(:db)])
  end

  def self.with_sum(total = 0)
    where('(invoice_tiers.tier_min <= ? OR invoice_tiers.tier_min IS NULL)', total)
      .where('(invoice_tiers.tier_max > ? OR invoice_tiers.tier_max IS NULL)', total)
  end

  def flat?
    tier_type == 'flat'
  end

  def fixed?
    tier_type == 'fixed'
  end

  def percent?
    tier_type == 'percent'
  end

  private

  def prevent_business_update
    errors.add(:business, "can't be updated!") if changes.include?('business_id')
  end

  def fix_dates
    self.start_at = start_at.nil? ? nil : start_at.beginning_of_month
    self.end_at = end_at.nil? ? nil : end_at.beginning_of_month
    self.end_at = start_at if !end_at.nil? && end_at < start_at
  end
end
