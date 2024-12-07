# == Schema Information
#
# Table name: zipcode_waitlists
#
#  id                        :integer          not null, primary key
#  zipcode                   :string(255)      not null
#  email                     :string(255)      not null
#  created_at                :datetime
#  updated_at                :datetime
#  apn_token                 :string(255)
#  platform                  :string(255)
#  source                    :string(255)
#  utm_source                :string(255)
#  utm_medium                :string(255)
#  utm_campaign              :string(255)
#  utm_term                  :string(255)
#  utm_content               :string(255)
#  latitude                  :float
#  longitude                 :float
#  doorkeeper_application_id :integer
#
# Indexes
#
#  index_zipcode_waitlist_on_email                       (email)
#  index_zipcode_waitlists_on_doorkeeper_application_id  (doorkeeper_application_id)
#  index_zipcode_waitlists_on_zipcode_and_email          (zipcode,email)
#

class ZipcodeWaitlist < ActiveRecord::Base
  include WisperAdapter

  belongs_to :doorkeeper_application, class_name: 'Doorkeeper::Application'

  validates :email, presence: true, format: /\A([\w.%+-]+)@([\w-]+\.)+(\w{2,})\z/i

  after_commit :publish_zipcode_waitlist_created, on: :create

  ADDRESS_ENTRY_SOURCE = 'address_entry'.freeze

  def publish_zipcode_waitlist_created
    broadcast_event(:created, prefix: true)
  end

  def geocode
    update(latitude: zipcode.to_lat, longitude: zipcode.to_lon) if valid_zipcode?
  end

  private

  def valid_zipcode?
    String(zipcode).length == 5 && String(zipcode) != '00000'
  end

  def mailchimp_waitlist_sync_data
    {
      email_address: email,
      status: 'subscribed',
      merge_fields: {
        ZIPCODE: zipcode,
        PLATFORM: platform || '',
        CREATED: created_at.strftime('%m/%d/%Y'),
        USER: RegisteredAccount.exists?(email: email) ? 1 : 0,
        SOURCE: source
      }.compact
    }
  end
end
