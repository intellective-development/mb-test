class ConsumerAPIV2::PaymentPartners::AuthorizationToken < BaseAPIV2
  include Shared::Helpers::PaymentPartners::Authenticatable

  before do
    error!('Invalid request', 400) unless valid_payment_partner_request?
  end

  namespace :payment_partner do
    desc 'Fetches RB\'s Braintree Clientside Authorization Token for API clients', Shared::Helpers::PaymentPartners::Authenticatable::PAYMENT_PARTNER_AUTH_HEADERS
    post :token do
      present :client_token, Braintree::ClientToken.generate
    end
  end
end
