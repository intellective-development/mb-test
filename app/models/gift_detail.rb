# == Schema Information
#
# Table name: gift_details
#
#  id              :integer          not null, primary key
#  recipient_name  :string
#  recipient_phone :string
#  recipient_email :string
#  message         :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :integer
#  event_sent      :boolean
#

# TODO: Incorporate normalization of phone numbers, sanitizatione etc.

class GiftDetail < ActiveRecord::Base
  include GiftDetail::SegmentSerializer
  include Iterable::Storefront::Serializers::GiftDetailSerializer

  has_one :order

  belongs_to :user

  phony_normalize :recipient_phone, default_country_code: 'US'
end
