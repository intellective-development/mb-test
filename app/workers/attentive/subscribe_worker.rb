# frozen_string_literal: true

module Attentive
  class SubscribeWorker
    include Sidekiq::Worker
    include WorkerErrorHandling

    sidekiq_options retry: 1,
                    queue: 'default'

    def perform_with_error_handling(user_id, phone)
      user = User.find(user_id)

      external_identifiers = build_external_identifiers(user)

      response = Attentive::Subscription.new(phone: phone).subscribe(external_identifiers: external_identifiers)

      raise_error(response) unless response.status == 202
    end

    private

    def build_external_identifiers(user)
      storefront = user.account&.storefront

      {
        clientUserId: user.email,
        customIdentifiers: [
          { name: 'storefrontId', value: storefront&.id },
          { name: 'storefrontPimName', value: storefront&.pim_name }
        ]
      }
    end

    def raise_error(response)
      raise Attentive::Errors::Subscription, response.body
    end
  end
end
