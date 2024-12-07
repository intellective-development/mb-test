# == Schema Information
#
# Table name: applied_deals
#
#  id             :integer          not null, primary key
#  deal_id        :uuid             not null
#  reservation_id :uuid             not null
#  shipment_id    :integer          not null
#  title          :string           not null
#  value          :decimal(10, 2)   not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  deal_type      :string
#  sponsor_type   :string
#  sponsor_id     :integer
#  sponsor_name   :string
#
# Indexes
#
#  index_applied_deals_on_deal_id                      (deal_id)
#  index_applied_deals_on_shipment_id                  (shipment_id)
#  index_applied_deals_on_sponsor_type_and_sponsor_id  (sponsor_type,sponsor_id)
#

class AppliedDeal < ActiveRecord::Base
  belongs_to  :shipment
  belongs_to  :sponsor, polymorphic: true
  has_one     :user, through: :shipment

  #------------------------------------------------------------
  # Instance methods
  #------------------------------------------------------------
  def sponsor_name
    sponsor.respond_to?(:name) ? sponsor.name : super
  end
end
