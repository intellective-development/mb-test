# == Schema Information
#
# Table name: video_gift_messages
#
#  id                 :integer          not null, primary key
#  order_id           :integer
#  qr_code_url        :string
#  sender_notified    :boolean
#  recipient_notified :boolean
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  record_video_url   :string
#  video_tag_id       :string(40)
#
# Indexes
#
#  index_video_gift_messages_on_order_id  (order_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#

class VideoGiftMessage < ActiveRecord::Base
  include Iterable::Storefront::Serializers::VideoGiftMessageSerializer

  belongs_to :order

  validates :video_tag_id, presence: true
  validates :video_tag_id, uniqueness: true

  def watch_video_url
    "#{ENV['CLIPJOY_WATCH_URL']}/?id=#{video_tag_id}"
  end
end
