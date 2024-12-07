# == Schema Information
#
# Table name: shipment_tracking_details
#
#  id                  :integer          not null, primary key
#  carrier             :string
#  reference           :string
#  validated           :boolean          default(FALSE), not null
#  last_checked_at     :datetime
#  shipment_id         :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  easypost_tracker_id :string
#  easypost_response   :json
#
# Indexes
#
#  index_shipment_tracking_details_on_shipment_id  (shipment_id)
#

class Shipment::TrackingDetail < ActiveRecord::Base
  include WisperAdapter

  auto_strip_attributes :reference

  belongs_to :shipment

  after_commit :publish_shipment_tracking_details_created, on: :create

  CARRIER_TRACKING_URL = {
    'ups': 'https://www.ups.com/track?loc=en_US&requester=ST/',
    'fedex': 'https://www.fedex.com/en-us/tracking.html',
    'gso': 'https://www.gls-us.com/tracking',
    'dhlexpress': 'https://www.dhl.com/en/express/tracking.html',
    '7dayexpress': 'https://www.7dayexpressonline.com/track-your-shipment/'
  }.with_indifferent_access.freeze
  GIO_EXPRESS_TRACKING_URL = 'https://www.gioexonline.com/ClientPortal?method=QuickTrack&OrderTrackingID='.freeze

  EASYPOST_EXCLUSIONS = %w[7NOW CartWheel].freeze

  HIDE_CARRIER_INFO = ['Other', 'Local Courier'].freeze

  # TODO: Add support for tracking webhooks to update status.

  def publish_shipment_tracking_details_created
    broadcast_event(:shipment_tracking_details_created)
  end

  def show_carrier_info?
    !HIDE_CARRIER_INFO.include?(carrier)
  end

  def carrier_tracking_url
    CARRIER_TRACKING_URL[carrier.downcase.gsub(/\s+/, '')]
  end

  def tracking_url
    easypost_response&.dig('public_url')
  end

  def tracking_number_url
    return GIO_EXPRESS_TRACKING_URL + reference if carrier == 'GIO Express'

    tracking_url
  end

  def easypost_supported?
    !EASYPOST_EXCLUSIONS.include?(carrier)
  end
end
