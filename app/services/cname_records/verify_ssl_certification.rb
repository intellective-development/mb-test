# frozen_string_literal: true

module CnameRecords
  # CnameRecords::VerifySslCertification
  class VerifySslCertification < Base
    include CnameRecords::AwsHelpers

    def call
      return :issued_and_processed unless cname_record.creating_ssl_certificate?

      CnameRecord.transaction do
        response = acm_client.describe_certificate(certificate_arn: cname_record.certificate_arn)
        if response.certificate.status == 'ISSUED'
          cname_record.ssl_certificate_created!
          :issued
        else
          :pending
        end
      end
    end
  end
end
