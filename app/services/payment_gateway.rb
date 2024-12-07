# frozen_string_literal: false

require 'sentry-ruby'

module PaymentGateway
  SETTLED_STATUS = %w[settled settlement_confirmed settlement_pending settling].freeze
  VOIDABLE_STATUS = %w[authorized submitted_for_settlement].freeze

  class Configuration
    include CriticalWarning

    attr_reader :gateway

    def initialize(business:, payment_type:)
      if business.present?
        critical_warning('Business credentials were incorrect. Fallback to Minibar.') unless business.braintree_credentials?
      else
        critical_warning('Business was nil. Fallback to Minibar.')
      end

      unless Feature[:skip_different_account_for_paypal].enabled?
        if payment_type == ::PaymentProfile::PAYPAL && !business&.default_business? # rubocop:disable Style/SoleNestedConditional
          @gateway = Braintree::Gateway.new(
            environment: Braintree::Configuration.environment,
            merchant_id: business.braintree_merchant_id,
            public_key: business.braintree_public_key,
            private_key: business.braintree_private_key
          )
        end
      end

      @gateway ||= default_braintree_gateway
    end

    private

    def default_braintree_gateway
      Braintree::Configuration.gateway
    end
  end

  module TransactionMethods
    delegate :status, to: :@transaction, allow_nil: true

    def consider_settled?
      self.class.consider_settled?(status)
    end

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def consider_settled?(status)
        SETTLED_STATUS.include? String(status)
      end
    end
  end

  class Metadata < Hash
    def initialize(result)
      super
      set_transaction_metadata(result.transaction) if result.transaction
      set_error_metadata(result) unless result.success?
    end

    def set_error_metadata(result)
      self[:params] = result.params[:transaction].dup if result.params.key?(:transaction)
      if result.errors
        error_hash = ->(e) { Hash[attribute: e.attribute, code: e.code, message: e.message] }
        self[:errors] = result.errors.map(&error_hash)
      end
    end

    def set_transaction_metadata(transaction)
      self[:avs_error_response_code] = transaction.try(:avs_error_response_code)
      self[:avs_postal_code_response_code] = transaction.try(:avs_postal_code_response_code)
      self[:avs_street_address_response_code] = transaction.try(:avs_street_address_response_code)
      self[:cvv_response_code] = transaction.try(:cvv_response_code)
      self[:gateway_rejection_reason] = transaction.try(:gateway_rejection_reason)
      self[:processor_authorization_code] = transaction.try(:processor_authorization_code)
      self[:processor_response_code] = transaction.try(:processor_response_code)
      self[:processor_response_text] = transaction.try(:processor_response_text)
      self[:additional_processor_response] = transaction.try(:additional_processor_response)
      self[:status] = transaction&.status&.to_s
      self[:type] = transaction&.type
      self[:merchant_account_id] = transaction&.merchant_account_id
      self[:order_id] = transaction&.order_id
      self[:id] = transaction&.id
      self[:amount] = String(transaction&.amount)
    end
  end

  class Transaction
    include TransactionMethods

    attr_reader :transaction

    # Returns a wrapped transaction or raises Braintree::NotFoundError
    def initialize(transaction_id, business, payment_type)
      gateway = Configuration.new(business: business, payment_type: payment_type).gateway
      @transaction = self.class.find!(transaction_id, gateway)
    end

    # This is a bit hacky, but gets the job done.
    def metadata
      pseudo_result = OpenStruct.new(transaction: transaction, success?: true)
      PaymentGateway::Metadata.new(pseudo_result)
    end

    def self.find!(transaction_id, gateway)
      gateway.transaction.find(transaction_id)
    end

    def self.find(transaction_id, business)
      gateway = Configuration.new(business: business).gateway
      find!(transaction_id, gateway)
      # Although I try to rescue this here to present a
      # consistent API there is a bug in Braintree or ruby
      # that prevents this error from being rescued in this
      # one circumstance.
    rescue Braintree::NotFoundError => e
      nil
    end
  end

  class MerchantAccount
    def self.find_by_supplier_id(supplier_id)
      return Settings.braintree.default_merchant_account_id unless supplier_id

      supplier = Supplier.active.find_by(id: String(supplier_id).split(',').first)
      supplier ? supplier.braintree_merchant_account_id : Settings.braintree.default_merchant_account_id
    end
  end

  class CreditCard
    def self.find_by_token(token, business, payment_type)
      gateway = Configuration.new(business: business, payment_type: payment_type).gateway
      gateway.credit_card.find(token)
    rescue Braintree::NotFoundError => e
      Rails.logger.info("Credit card not found. Error message: #{e.message}. Backtrace: #{e.backtrace.join("\n")}")

      nil
    end
  end

  class TransactionalBase
    include TransactionMethods

    RETRYABLES = [SocketError].freeze

    attr_reader :result, :metadata, :transaction, :options, :gateway

    delegate :errors, :message, to: :result, allow_nil: true

    def initialize(transaction_id, business, payment_type, **options)
      @gateway = Configuration.new(business: business, payment_type: payment_type).gateway
      @transaction_id = transaction_id
      @options = options
      @success = false
    end

    def success?
      @success
    end

    # This let's us retry if process fails. This could be an inline
    # retry or by scheduling a new Job if this is inside a Job.
    # To retry inline you must return true from the block. See
    # #process_or_retry below for an example.
    def process_or_rescue_with(from: RETRYABLES)
      raise ArgumentError, 'no block given' unless block_given?

      begin
        process
      rescue *from => e
        # retry cannot be called outside of the begin block so we
        # return true if we want to retry
        retry if yield e
      end
    end

    def process_or_retry(tries: 3, max_wait: 1)
      process_or_rescue_with do |exception|
        raise exception if (tries -= 1).zero?

        sleep_for(tries, max_wait)
        true # tells the process_or_rescue_with to retry
      end
    end

    def process_without_notify
      @result = action
      if @result
        dump_result if ENV['DUMP_GATEWAY']
        @transaction = @result.transaction if @result.respond_to?(:transaction)
        @metadata = Metadata.new(@result)
        @success = @result.success?
      end
    end

    def dump_result
      class_path = self.class.name.tableize.singularize
      result_type = @result.success? ? @result.transaction.status : 'error'
      sub_path = ENV['DUMP_GATEWAY'].empty? ? 'tmp' : ENV['DUMP_GATEWAY']
      yaml_path = Pathname.new(Rails.root + [sub_path, class_path].join('/'))
      FileUtils.mkdir_p(yaml_path) unless yaml_path.exist?
      yaml_file = "#{yaml_path}/#{result_type}.yml"
      File.open(yaml_file, 'w') do |file|
        file.puts YAML.dump(@result)
      end
    end

    def process
      process_without_notify

      notify_sentry unless success?
      success?
    end

    def notify_sentry
      SentryMessage.new(self, backtrace: caller).perform
    end

    def action
      raise NotImplementedError
    end

    private

    def sleep_for(tries, max_wait)
      sleep [(max_wait.to_f / 2.0 + rand / 2.5) / tries.to_f, max_wait].min
    end
  end

  class Capture < TransactionalBase
    def action
      gateway.transaction.submit_for_settlement(@transaction_id)
    end
  end

  class Void < TransactionalBase
    def action
      gateway.transaction.void(@transaction_id)
    end
  end
end
