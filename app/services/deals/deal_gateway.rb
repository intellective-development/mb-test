require 'faraday'
require 'jiffy_bag'

module Deals
  module DealGateway
    attr_reader :host, :path, :user, :page, :per_page, :total_pages

    HOST = ENV['DEALS_HOST']
    PORT = ENV['DEALS_PORT']
    AUTH_TOKEN = ENV['DEALS_AUTH_TOKEN']

    module Attributes
      def self.included(base)
        base.class_exec { attr_accessor(*base.attribute_names) }
      end

      def initialize(attributes = {})
        attributes.symbolize_keys!
        self.class.attribute_names.map { |attribute| public_send("#{attribute}=", attributes[attribute]) }
      end

      def [](key)
        instance_variable_get(:"@#{key}")
      end
    end

    class Deal
      def self.attribute_names
        %i[
          id type subject category description applicable_order quota quota_remaining
          single_use starts_at ends_at maximum_value minimum_shipment_value minimum_units
        ]
      end

      include Attributes

      delegate :name, to: :subject, prefix: true

      def initialize(attributes = {})
        super
        if @subject.is_a?(Hash)
          subject_class = @subject['type'].classify.constantize
          @subject = subject_class.friendly.find(@subject['key'])
        end
      end

      def human_type
        self['type'].titleize
      end

      def short_title
        "#{human_type} in #{subject_name}."
      end

      def long_title
        "#{human_type} in #{subject_name} for #{ordinal_order}."
      end

      def ordinal_order
        return 'all orders' if applicable_order.to_i.zero?

        "the #{applicable_order.ordinalize} #{'order'.pluralize(applicable_order)}"
      end
    end

    class Reservation
      def self.attribute_names
        %i[deal_id expires_at order_id reservation_id used]
      end

      include Attributes
    end

    class NotifyShipmentPaid
      def initialize(attributes, *reservation_ids)
        @attributes      = attributes
        @reservation_ids = reservation_ids.flatten
      end

      def call
        payload = JiffyBag.encode(attributes: @attributes, reservation_ids: @reservation_ids)

        Sidekiq::Client.push(
          'class' => 'ReservationsUsedWorker',
          'queue' => 'deals_default',
          'args' => Array(payload)
        )
      end
    end

    class Base
      include SentryNotifiable

      attr_reader :status

      private

      def send_request(method)
        connection = Faraday.new
        response = connection.public_send(method) do |request|
          request.url @path
          request.params = @params
          request.body = @request_body.to_json if @request_body.present?
          request.headers['Content-Type'] = 'application/json'
          request.headers['Authorization'] = "Token token=#{AUTH_TOKEN}"
          request.options.timeout = 5
          request.options.open_timeout = 5
        end

        @status = response.status
        block_given? ? yield(response) : response
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
        notify_sentry_and_log(e)
        false
      end
    end

    class ContextQuery < Base
      def initialize(params = {})
        @path = "#{HOST}/api/v1/query/context"
        @params = params
      end

      def call
        send_request(:get) do |response|
          if @status == 200
            @total_pages = response.headers['x-total-pages'].to_i
            @deals = JSON.parse(response.body)
          end
        end
      end

      def deals
        Array(@deals).flat_map { |attributes| Deal.new(attributes) }
      end
    end

    class Reservations < Base
      def initialize(params = {})
        @path = "#{HOST}/api/v1/reservations"
        @request_body = { deals: params[:deals].as_json } unless params[:deals].nil?
        @params = params
        @result = {}
      end

      def call
        send_request(:post) do |response|
          @result = JSON.parse(response.body)
          [201, 409].include?(@status) # return true if an expected status.
        end
      rescue JSON::ParserError => e
        Rails.logger.error("Error parsing JSON: #{e.message}; URL: #{@path}; Params: #{@params};")
        raise DealsGatewayBadResponseException, "Bad response from Deals Gateway. URL: #{@path}; Params: #{@params}; Exception: #{e}"
      end

      def successful
        @successful ||= @result.fetch('successful', []).map { |attr| Reservation.new(attr) }
      end

      def errors
        @errors ||= @result['errors'].map { |attributes| Reservation.new(attributes) }
      end
    end
  end
end
