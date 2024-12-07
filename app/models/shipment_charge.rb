# == Schema Information
#
# Table name: chargeables
#
#  id              :integer          not null, primary key
#  braintree       :boolean          default(TRUE), not null
#  credit          :boolean
#  reason_id       :integer
#  shipment_id     :integer
#  user_id         :integer
#  description     :text
#  created_at      :datetime
#  updated_at      :datetime
#  amount          :decimal(, )
#  processed       :boolean          default(FALSE), not null
#  financial       :boolean          default(TRUE), not null
#  line_item_id    :integer
#  type            :string(64)       not null
#  charge_id       :integer
#  substitution_id :integer
#  adjustment_type :integer
#  order_id        :integer
#  supplier_id     :integer
#  taxes           :boolean
#
# Indexes
#
#  chargeables_order_id_idx              (order_id)
#  index_chargeables_on_adjustment_type  (adjustment_type)
#  index_chargeables_on_charge_id        (charge_id)
#  index_chargeables_on_line_item_id     (line_item_id)
#  index_chargeables_on_shipment_id      (shipment_id)
#  index_chargeables_on_type_and_id      (type,id)
#

#  ____                                 _____ _______ _____
# |  _ \                               / ____|__   __|_   _|
# | |_) | _____      ____ _ _ __ ___  | (___    | |    | |
# |  _ < / _ \ \ /\ / / _` | '__/ _ \  \___ \   | |    | |
# | |_) |  __/\ V  V / (_| | | |  __/  ____) |  | |   _| |_
# |____/ \___| \_/\_/ \__,_|_|  \___| |_____/   |_|  |_____|
class ShipmentCharge < Chargeable
  delegate :consider_charged?, to: :charge
  validates :charge, presence: true
end
