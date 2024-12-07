# frozen_string_literal: true

module CnameRecords
  # CnameRecords::CreateAPIGatewayDomain
  class CreateAPIGatewayDomain < CnameRecords::Base
    include CnameRecords::AwsHelpers

    API_GATEWAY_MAPPING_STAGE = '$default'
    API_GATEWAY_ENDPOINT_TYPE = ['REGIONAL'].freeze

    def call
      cname_record.creating_custom_domain!

      CnameRecord.transaction do
        find_and_save_certificate! if cname_record.certificate_arn.blank?

        custom_domain_response = find_or_create_custom_domain
        cname_record.update!(api_gateway_domain: custom_domain_response.regional_domain_name)

        find_or_create_api_mapping
        cname_record.custom_domain_created!
      end

      { status: :success, cname_record: cname_record }
    end

    private

    def find_and_save_certificate!
      certificate = find_certificate_by_domain(cname_record.domain)

      cname_record.update(certificate_arn: certificate.certificate_arn)
    rescue StandardError => _e
      raise "Unable to find a certificate to the domain: #{cname_record.domain}"
    end

    def find_or_create_custom_domain
      api_gateway_client.get_domain_name(domain_name: cname_record.domain)
    rescue Aws::APIGateway::Errors::NotFoundException
      api_gateway_client.create_domain_name(
        domain_name: cname_record.domain,
        regional_certificate_arn: cname_record.certificate_arn,
        endpoint_configuration: { types: API_GATEWAY_ENDPOINT_TYPE }
      )
    end

    def api_id
      return @api_id if defined?(@api_id)

      apis = api_gateway_client_v2.get_apis
      api = apis.items.find { |a| a.name == API_GATEWAY_NAME }

      raise "Could not find API with name #{API_GATEWAY_NAME}" unless api

      @api_id = api.api_id
    end

    def find_or_create_api_mapping
      api_mappings = api_gateway_client_v2.get_api_mappings(domain_name: cname_record.domain)
      existing_mapping = api_mappings.items.find do |mapping|
        mapping.api_id == api_id && mapping.stage == API_GATEWAY_MAPPING_STAGE
      end

      create_api_mapping unless existing_mapping
    end

    def create_api_mapping
      api_gateway_client_v2.create_api_mapping(
        domain_name: cname_record.domain,
        api_id: api_id,
        stage: API_GATEWAY_MAPPING_STAGE
      )
    end
  end
end
