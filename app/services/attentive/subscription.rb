# frozen_string_literal: true

module Attentive
  class Subscription
    include Attentive::Connection

    SINGUP_SOURCE_ID = ENV['ATTENTIVE_SUBSCRIPTION_SIGNUP_SOURCE_ID']

    def initialize(phone:)
      @phone = phone
    end

    def subscribe(external_identifiers:)
      return unless Feature[:attentive_subscription].enabled?

      url = 'subscriptions'
      params = subscribe_params(external_identifiers)

      connection.post(url, params)
    end

    private

    attr_reader :phone

    def subscribe_params(external_identifiers)
      {
        user: { phone: phone },
        signUpSourceId: SINGUP_SOURCE_ID,
        externalIdentifiers: external_identifiers
      }
    end
  end
end
