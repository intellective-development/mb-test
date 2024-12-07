# == Schema Information
#
# Table name: counts
#
#  id         :integer          not null, primary key
#  value      :float            default(0.0)
#  date       :date             not null
#  type       :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#  values     :integer          default(1)
#  average    :float            default(0.0)
#
# Indexes
#
#  index_counts_on_date      (date)
#  index_counts_on_datetype  (lower((type)::text), date)
#  index_counts_on_type      (type)
#

class Count < ActiveRecord::Base
  validates :date,  presence: true
  validates :type,  presence: true

  self.inheritance_column = :_type_disabled

  scope :of,    ->(type) { where('lower(type) = ?', type.downcase) }
  scope :like,  ->(type) { where('lower(type) LIKE ?', "%#{type.downcase}%") }

  def self.total(type)
    Count.of(type).sum(:value)
  end

  def self.total_for_period(type, starts_at = Date.today - 7.days, ends_at = Date.today)
    Count.of(type).where('date >= ?', starts_at).where('date <= ?', ends_at).sum(:value)
  end

  def self.total_values_for_period(type, starts_at = Date.today - 7.days, ends_at = Date.today)
    Count.of(type).where('date >= ?', starts_at).where('date <= ?', ends_at).sum(:values)
  end

  def self.increment(type, value = 1, date = Date.today)
    value ||= 1
    today = Count.of(type).find_by(date: date)
    if today
      today.value   = today.value.to_f + value
      today.values  = today.values.to_i + 1
      today.average = today.value.to_f / today.values.to_f
      today.save
    else
      Count.create(type: type, date: date, value: value)
    end
  end
end
