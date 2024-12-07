# frozen_string_literal: true

module CnameRecords
  # CnameRecords::AwsHelpers
  module AwsHelpers
    extend ActiveSupport::Concern

    private

    API_GATEWAY_NAME = ENV['AWS_API_GATEWAY_NAME'].freeze

    def client_initializer
      {
        region: ENV['AWS_REGION'],
        credentials: credentials
      }
    end

    def credentials
      ::Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
      )
    end

    def find_certificate_by_domain(domain)
      certificates_response = acm_client.list_certificates
      certificates_response.certificate_summary_list.find do |response|
        domain.match?(response.domain_name)
      end
    end

    def acm_client
      @acm_client ||= Aws::ACM::Client.new(client_initializer)
    end

    def api_gateway_client
      @api_gateway_client ||= Aws::APIGateway::Client.new(client_initializer)
    end

    def api_gateway_client_v2
      @api_gateway_client_v2 ||= Aws::ApiGatewayV2::Client.new(client_initializer)
    end
  end
end
