# == Schema Information
#
# Table name: holidays
#
#  id             :integer          not null, primary key
#  date           :string(20)       not null
#  user_id        :integer
#  created_at     :datetime
#  updated_at     :datetime
#  shipping_types :string           default([]), is an Array
#

class Holiday < ActiveRecord::Base
  DATE_FORMAT = '%m/%d/%Y'.freeze

  has_paper_trail

  belongs_to :user
  has_many :supplier_holidays, dependent: :destroy
  has_many :suppliers, through: :supplier_holidays

  validates :date, presence: true

  #--------------------------------------
  # Scopes
  #--------------------------------------
  scope :upcoming_by_shipping_type, ->(shipping_type, origin = Time.zone.now.beginning_of_day) { where("to_date(date, 'MM/DD/YYYY') >= ? and ((coalesce(array_length(shipping_types, 1), 0) = 0 or coalesce(array_length(shipping_types, 1), 0) = ?) or ? = ANY(shipping_types))", origin, ShippingMethod::IN_STORE_SHIPPING_TYPES.size, shipping_type) }
  scope :upcoming_all, ->(origin = Time.zone.now.beginning_of_day) { where("to_date(date, 'MM/DD/YYYY') >= ?", origin) }
  scope :upcoming, ->(origin = Time.zone.now.beginning_of_day) { where("to_date(date, 'MM/DD/YYYY') >= ? and (coalesce(array_length(shipping_types, 1), 0) = 0 or coalesce(array_length(shipping_types, 1), 0) = ?)", origin, ShippingMethod::IN_STORE_SHIPPING_TYPES.size) }
  scope :today, ->(origin = Time.zone.now.beginning_of_day) { where("to_date(date, 'MM/DD/YYYY') = ? and (coalesce(array_length(shipping_types, 1), 0) = 0 or coalesce(array_length(shipping_types, 1), 0) = ?)", origin, ShippingMethod::IN_STORE_SHIPPING_TYPES.size) }
  scope :today_breaks, ->(origin = Time.zone.now.beginning_of_day) { where("to_date(date, 'MM/DD/YYYY') = ? and coalesce(array_length(shipping_types, 1), 0) > 0 and coalesce(array_length(shipping_types, 1), 0) < ?", origin, ShippingMethod::IN_STORE_SHIPPING_TYPES.size) }

  #-----------------------------------
  # Class methods
  #-----------------------------------
  attr_accessor :end_date
  attr_accessor :start_date

  def self.admin_grid(params = {})
    if params[:name].present?
      Holiday.joins(:supplier_holidays).joins(:suppliers).where('lower(suppliers.name) LIKE ?', "%#{params[:name].downcase}%").distinct
    else
      Holiday.all
    end
  end

  #--------------------------------------
  # Instance methods
  #--------------------------------------
  def as_date
    Time.zone.parse(date)
  end
end
