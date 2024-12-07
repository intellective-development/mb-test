module PaymentGateway
  class SentryMessage
    include SentryNotifiable

    delegate :result, :transaction, :options, :metadata, to: :@transactional

    def initialize(transactional, **args)
      @message = args.delete(:message)
      @args = args
      @transactional = transactional
      @user_id = options[:user_id] || shipment&.order&.user_id
      @extras = {}
      @extras[:shipment_id] = options[:shipment_id] || shipment&.id
      @extras[:order_id] = options[:order_id] || shipment&.order_id
      @extras[:order_number] = shipment&.order&.number
      @extras[:business_name] = options[:business_name] || shipment&.order&.storefront&.business&.name
      @extras[:order_number] = options[:order_number] || shipment&.order&.number
      @extras[:payment_profile_id] = options[:payment_profile_id] || shipment&.order&.payment_profile_id
      @extras[:metadata] = metadata if metadata
      @extras[:metadata_json] = metadata&.to_json if metadata
      @extras[:error_class] = transactional&.class&.name
      @extras[:result] = transactional&.inspect&.to_json
    end

    def attributes
      @attributes ||= begin
        attr_hash = {
          level: 'error',
          extra: @extras
        }
        attr_hash[:user] = { id: @user_id } if @user_id
        attr_hash.merge!(@args)
        attr_hash
      end
    end

    def perform
      message_sentry_and_log(message, attributes)
    end

    def message
      'PaymentGateway: ' << String(@message || @transactional&.message || 'Unexpected result in payment gateway')
    end

    def shipment
      @shipment ||= begin
        return nil unless transaction&.order_id

        s = GlobalID.find(transaction&.order_id)
        s.is_a?(Shipment) ? s : nil
      rescue StandardError
        nil
      end
    end
  end
end
