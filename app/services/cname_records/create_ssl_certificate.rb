# frozen_string_literal: true

module CnameRecords
  # CnameRecords::CreateSslCertificate
  class CreateSslCertificate < Base
    include CnameRecords::AwsHelpers

    def call
      CnameRecord.transaction do
        cname_record.creating_ssl_certificate!

        existing_certificate = find_certificate_by_domain(cname_record.domain)
        certificate_response = existing_certificate || request_certificate
        cname_record.update!(certificate_arn: certificate_response.certificate_arn)
      end
    end

    private

    def request_certificate
      acm_client.request_certificate(domain_name: cname_record.domain)
    end
  end
end
