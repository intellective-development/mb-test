class BraintreeWebhooks < BaseAPI
  helpers do
    def parse_notification
      @notification = Braintree::WebhookNotification.parse(params[:bt_signature], params[:bt_payload])
    rescue Braintree::InvalidSignature
      error!('Invalid Signature', 401)
    end
  end

  namespace :dispute do
    desc 'Webhook endpoint for Braintree Dispute notifications.'
    params do
      requires :bt_payload
      requires :bt_signature
    end
    before do
      parse_notification
    end
    post do
      ProcessDisputeService.new(@notification.dispute).call if %w[dispute_opened dispute_won dispute_lost].include?(@notification.kind)

      status 200
    end
  end

  namespace :subscription do
    desc 'Webhook endpoint for Braintree Subscription notifications.'
    params do
      requires :bt_payload
      requires :bt_signature
    end
    before do
      parse_notification
    end
    post do
      ::Memberships::Webhook.new(@notification).call

      status 200
    end
  end
end
