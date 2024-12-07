# == Schema Information
#
# Table name: payment_profile_update_links
#
#  id         :uuid             not null, primary key
#  order_id   :integer
#  expire_at  :datetime
#  used_at    :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  payment_profile_update_link_general_index  (id,expire_at,used_at)
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#
class PaymentProfileUpdateLink < ActiveRecord::Base
  belongs_to :order, optional: false

  validates :order, presence: true

  attribute :id, :string
  attribute :expire_at, :datetime, default: -> { Time.now.utc + 12.days }
  attribute :used_at, :datetime

  def url
    base_url = order.storefront.priority_hostname
    "https://#{base_url}/storefront/update-payment-profile/#{id}"
  end
end
