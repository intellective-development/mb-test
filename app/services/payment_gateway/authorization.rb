module PaymentGateway
  class Authorization < TransactionalBase
    delegate :current_state, :transition_to, :transition_to!, to: :state_machine
    delegate :id, :status, to: :transaction, prefix: true, allow_nil: true

    attr_reader :gateway

    def initialize(amount, card_token, merchant_account_id, business, payment_type, **options)
      raise Minibar::NilAttributeError, :amount if amount.nil?

      @gateway = Configuration.new(business: business, payment_type: payment_type).gateway
      @amount = String(BigDecimal(amount, 15).round(2))
      @card_token = card_token
      @merchant_account_id = custom_merchant_account_id(business, payment_type) || merchant_account_id
      @options = options
      Sentry.set_extras(sale_params: sale_params)
    end

    def state_machine
      @state_machine ||= AuthorizationStateMachine.new(self)
    end

    # Shorthand for defining state methods e.g. #pending?
    #
    # def pending?
    #   current_state == pending
    # end
    AuthorizationStateMachine.states.each do |state|
      define_method "#{state}?" do
        current_state == state
      end
    end

    def process
      process_without_notify

      return true if transition_to(:authorized)

      # This is control flow and more valid than ||. Transition to declined or failed.
      transition_to(:declined) or transition_to(:failed)
      false
    end

    def action
      gateway.transaction.sale(sale_params)
    end

    def sale_params
      params = {
        custom_fields: custom_fields,
        amount: @amount,
        payment_method_token: @card_token,
        merchant_account_id: @merchant_account_id
      }

      params[:order_id] = @options[:unique_id] if @options.key?(:unique_id)
      params[:options] = @options[:options] if @options.key?(:options)
      params
    end

    def custom_fields
      fields = {}
      fields[:shipment_id] = @options[:shipment_id] if @options.key?(:shipment_id)
      fields[:order_id] = @options[:order_id] if @options.key?(:order_id)
      fields[:business_name] = @options[:business_name] if @options.key?(:business_name)
      fields[:order_number] = @options[:order_number] if @options.key?(:order_number)
      fields[:partner_store_id] = @options[:partner_store_id] if @options.key?(:partner_store_id)
      fields[:partner_total_amount] = @options[:partner_total_amount] if @options.key?(:partner_total_amount)
      fields[:partner_gift_card_amount] = @options[:partner_gift_card_amount] if @options.key?(:partner_gift_card_amount)
      fields[:partner_promo_amount] = @options[:partner_promo_amount] if @options.key?(:partner_promo_amount)
      fields
    end

    private

    def custom_merchant_account_id(business, payment_type)
      Settings.braintree.default_rb_merchant_account_id if payment_type == ::PaymentProfile::PAYPAL && !business&.default_business?
    end
  end
end
