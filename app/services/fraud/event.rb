require 'sift'

module Fraud
  class Event
    include SiftRetryableCaller

    def initialize(user, session, request, alt_event_type = nil, alt_properties = nil)
      @user = user
      @ip = request&.remote_ip
      @user_agent = request&.user_agent
      @time = Time.zone.now
      # Alternate constructor for Sidekiq to serialize/deserialize (to be moved later into DB for tracking)
      @alt_event_type = alt_event_type
      @alt_properties = alt_properties
      @session_id = session_id(session)
    end

    def call
      event = @alt_event_type || self.class.event_type
      props = @alt_properties || properties
      notify_sift(event, props)
    end

    def call_async
      SiftWorker.perform_async(self.class.event_type, properties)
    end

    private

    def client
      @client ||= Sift::Client.new(
        api_key: ENV['SIFT_SCIENCE_API_KEY'],
        account_id: ENV['SIFT_ACCOUNT_ID'],
        version: ENV['SIFT_API_VERSION'] || 205
      )
    end

    def properties
      {
        '$user_id' => @user&.referral_code,
        '$ip' => @ip,
        '$browser' => {
          '$user_agent' => @user_agent
        },
        '$session_id' => @session_id,
        'corporate_customer' => @user&.corporate?,
        'vip_customer' => @user&.vip?,
        'oauth_application' => @user&.doorkeeper_application&.name,
        '$time' => (@time.to_f * 1000).to_i
      }
    end

    def address_properties(address)
      {
        '$name' => address&.name,
        '$phone' => address&.phone,
        '$address_1' => address&.address1,
        '$address_2' => address&.address2,
        '$city' => address&.city,
        '$region' => address&.state_abbr_name,
        '$country' => 'US',
        '$zipcode' => address&.zip_code
      }
    end

    def payment_profile_properties(payment_profile)
      {
        '$payment_type' => '$credit_card',
        '$payment_gateway' => '$braintree',
        '$card_bin' => payment_profile&.bin,
        '$card_last4' => payment_profile&.last_digits
      }
    end

    def currency_amount(value)
      value && Integer(value * 1_000_000) # 115940000 = $115.94
    end

    def notify_sift(event, props, opts = {})
      call_and_retry { client.track(event, props, opts) }
    end

    def session_id(session)
      session.id.public_id || session.id
    rescue StandardError
      session&.id
    end
  end
end
