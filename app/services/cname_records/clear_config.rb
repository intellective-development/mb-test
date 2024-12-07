# frozen_string_literal: true

module CnameRecords
  # CnameRecords::ClearConfig
  class ClearConfig < BaseService
    include CnameRecords::AwsHelpers

    def initialize(cname_record) # rubocop:disable Lint/MissingSuper
      @cname_record = cname_record
    end

    def call
      delete_ssl_certificate unless cname_record.internal?
      delete_custom_domain
    rescue Aws::APIGateway::Errors::NotFoundException, Aws::ACM::Errors::InvalidArnException
      nil
    end

    private

    attr_reader :cname_record

    def delete_ssl_certificate
      acm_client.delete_certificate(certificate_arn: cname_record.certificate_arn)
    end

    def delete_custom_domain
      api_gateway_client.delete_domain_name(domain_name: cname_record.domain)
    end
  end
end
