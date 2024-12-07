# frozen_string_literal: true

module CnameRecords
  # CnameRecords::CreateSslCertificateWorker
  class CreateSslCertificateWorker
    include Sidekiq::Worker
    include WorkerErrorHandling

    sidekiq_options retry: 5, queue: 'default'

    def perform_with_error_handling(cname_record_id)
      cname_record = CnameRecord.find(cname_record_id)

      CnameRecords::CreateSslCertificate.call(cname_record)

      VerifySslCertificationWorker.perform_in(CnameRecord::SSL_ISSUING_WAIT_TIME, cname_record.id)
    end
  end
end
