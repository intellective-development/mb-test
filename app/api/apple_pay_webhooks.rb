class ApplePayWebhooks < BaseAPI
  require 'jwt'

  namespace :notifications do
    desc 'Webhook endpoint for Apple Pay notifications.'
    params do
      requires :responseBodyV1
      requires :notification_type
    end
    post do
      Rails.logger.error("[ApplePay] Received webhook update: Event #{params[:notification_type]} with params #{params}")
      if params[:notification_type] == 'REFUND'
        transaction_id = params[:responseBodyV1][:original_transaction_id]
        charge = Charge.find_by(transaction_id: transaction_id)
        if charge&.chargeable&.order&.present?
          message = if charge.voided? || charge.refunded?
                      "Refund - #{charge.amount}"
                    elsif !charge.customer_refunds.empty?
                      "Refund - #{charge.customer_refunds.last.amount}"
                    end
          PushNotificationWorker.perform_async(:custom_message, charge.chargeable.order.user.email, { content: message }) unless message.nil?
        end
      end

      status 200
    end
  end

  namespace :notification do
    desc 'Webhook endpoint for Apple Pay notifications.'
    params do
      requires :signedPayload
    end
    post do
      data = JWT.decode params[:signedPayload], nil, false
      header, encoded_hash, signature = data.split('.')
      # encoded_hash = data.first
      payload = ActiveSupport::JSON.decode(Base64.decode64(encoded_hash))
      Rails.logger.error("[ApplePay] Received webhook update: Event #{payload[:notification_type]} with params #{payload}")
      if payload['notification_type'] == 'REFUND'
        data = JWT.decode payload['signedTransactionInfo'], nil, false
        header, encoded_hash, signature = payload['signedTransactionInfo'].split('.')
        # encoded_hash = data.first
        transaction_info = ActiveSupport::JSON.decode(Base64.decode64(encoded_hash))
        Rails.logger.error("[ApplePay] Received webhook update: transaction_info #{transaction_info}")
        transaction_id = transaction_info['original_transaction_id']
        charge = Charge.find_by(transaction_id: transaction_id)
        if charge&.chargeable&.order&.present?
          message = if charge.voided? || charge.refunded?
                      "Refund - #{charge.amount}"
                    elsif !charge.customer_refunds.empty?
                      "Refund - #{charge.customer_refunds.last.amount}"
                    end
          PushNotificationWorker.perform_async(:custom_message, charge.chargeable.order.user.email, { content: message }) unless message.nil?
        end
      end

      status 200
    end
  end
end
