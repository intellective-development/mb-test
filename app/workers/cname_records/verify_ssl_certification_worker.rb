# frozen_string_literal: true

module CnameRecords
  # CnameRecords::VerifySslCertificationWorker
  class VerifySslCertificationWorker
    include Sidekiq::Worker
    include WorkerErrorHandling

    sidekiq_options retry: 5, queue: 'default'

    def perform_with_error_handling(cname_record_id)
      cname_record = CnameRecord.find(cname_record_id)
      result = CnameRecords::VerifySslCertification.call(cname_record)

      case result
      when :issued
        CnameRecords::CreateCustomDomain.call(cname_record)
      when :pending
        self.class.perform_in(CnameRecord::SSL_ISSUING_WAIT_TIME, cname_record.id)
      end
    end
  end
end
