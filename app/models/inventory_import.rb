# == Schema Information
#
# Table name: inventory_imports
#
#  id                       :integer          not null, primary key
#  active_variants_at_start :integer          default(0)
#  active_variants_at_end   :integer          default(0)
#  new_products             :integer          default(0)
#  new_variants             :integer          default(0)
#  total_records            :integer          default(0)
#  updated_variants         :integer          default(0)
#  invalid_records          :integer          default(0)
#  zeroed_products          :integer          default(0)
#  supplier_id              :integer
#  data_feed_id             :integer
#  success                  :boolean          default(FALSE), not null
#  started_at               :datetime
#  completed_at             :datetime
#  has_changed              :boolean          default(FALSE), not null
#

class InventoryImport < ActiveRecord::Base
  belongs_to :data_feed
  belongs_to :supplier

  scope :pending,    -> { where(success: false, completed_at: nil) }
  scope :completed,  -> { where(success: true) }
  scope :failed,     -> { where(success: false).where.not(completed_at: nil) }

  before_create :set_started_at

  def finish_import(options = {})
    update(options.merge(completed_at: Time.zone.now))
  end

  private

  def set_started_at
    self.started_at = Time.zone.now if started_at.nil?
  end
end
