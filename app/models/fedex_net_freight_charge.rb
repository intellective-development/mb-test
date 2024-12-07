# == Schema Information
#
# Table name: fedex_net_freight_charges
#
#  id           :integer          not null, primary key
#  shipment_lbs :integer
#  zone2        :float
#  zone3        :float
#  zone4        :float
#  zone5        :float
#  zone6        :float
#  zone7        :float
#  zone8        :float
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_fedex_net_freight_charges_on_shipment_lbs  (shipment_lbs) UNIQUE
#

class FedexNetFreightCharge < ActiveRecord::Base
  def self.calculate_fee(weight = 0, millage = 0)
    zone = FedexNetFreightCharge.get_zone_by_millage(millage)
    unless zone.nil?
      fedex_charge = find_charges_by_weight(weight)
      fedex_charge&.send("zone#{zone}")
    end
  end

  def self.get_zone_by_millage(millage = 0)
    case millage.ceil
    when 0..150 then 2
    when 151..300 then 3
    when 301..600 then 4
    when 601..1000 then 5
    when 1001..1400 then 6
    when 1401..1800 then 7
    when 1801..Float::INFINITY then 8
    end
  end

  def self.find_charges_by_weight(weight = 0)
    where(shipment_lbs: weight.ceil).first
  end
end
