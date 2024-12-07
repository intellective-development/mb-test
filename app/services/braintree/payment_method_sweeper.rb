module Braintree
  class PaymentMethodSweeper
    include SentryNotifiable

    def initialize; end

    def call
      PaymentProfile.where(active: false, deleted_at: nil).find_each do |payment_profile|
        gateway.credit_card.delete(payment_profile.braintree_token)
      rescue Braintree::NotFoundError => e
        # Credit Card has already been deleted from Braintree.
        notify_sentry_and_log(e)
      ensure
        payment_profile.update(deleted_at: Time.current)
      end
    end

    private

    def gateway
      @gateway ||= Braintree::Gateway.new(
        environment: :production,
        merchant_id: Settings.braintree.merchant_id,
        public_key: Settings.braintree.public_key,
        private_key: Settings.braintree.private_key
      )
    end
  end
end
