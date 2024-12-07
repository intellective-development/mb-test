# == Schema Information
#
# Table name: support_interactions
#
#  id                 :integer          not null, primary key
#  channel            :integer
#  external_ticket_id :string
#  user_id            :integer
#  order_id           :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_support_interactions_on_order_id  (order_id)
#  index_support_interactions_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#  fk_rails_...  (user_id => users.id)
#

class SupportInteraction < ActiveRecord::Base
  # Initially we are only supporting tracking of FreshDesk tickets. This
  # includes inbound interactions from web, sms or email. In future we may
  # also wish to track FreshPhone and LiveChat interactions if we are able
  # to associate with an order or user.
  enum channel: {
    freshdesk_ticket: 1
  }

  belongs_to :user
  belongs_to :order
end
