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

class DeliveryBreak < ActiveRecord::Base
  has_paper_trail

  belongs_to :supplier
  has_many :shipping_methods, ->(obj) { where('shipping_methods.id IN (?)', obj.shipping_method_ids) }, through: :supplier

  validates :date, :start_time, :end_time, :supplier, presence: true
  validates :start_time, :end_time, format: /\d{1,2}:\d{2}\s*(am|pm)?/i

  before_save :apply_to_all_shipping_methods, if: :apply_to_all?
  after_save :reload_shipping_methods, if: :shipping_method_ids_changed?

  #--------------------------------------
  # Scopes
  #--------------------------------------
  scope :without_supplier_breaks, -> { where(type: nil) }
  scope :upcoming, ->(origin = Time.zone.now.beginning_of_day) { where("to_date(date, 'MM/DD/YYYY') >= ?", origin) }
  scope :today_breaks, ->(origin = Time.zone.now.beginning_of_day) { where("to_date(date, 'MM/DD/YYYY') = ?", origin) }

  #--------------------------------------
  # Instance_methods
  #--------------------------------------
  def shipping_method_ids
    self[:shipping_method_ids]
  end

  def shipping_method_ids=(ids)
    shipping_method_ids_will_change!
    self[:shipping_method_ids] = Array(ids)
  end

  def shipping_methods=(objects)
    self.shipping_method_ids = Array(objects).lazy.map(&:id).reject(&:nil?).force
  end

  def as_date
    Time.zone.parse(date)
  end

  private

  def reload_shipping_methods
    shipping_methods(force: true)
  end

  def apply_to_all_shipping_methods
    self.shipping_method_ids = supplier.shipping_method_ids
  end
end
