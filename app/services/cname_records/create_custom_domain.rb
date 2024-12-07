# frozen_string_literal: true

module CnameRecords
  # CnameRecords::CreateCustomDomain
  class CreateCustomDomain < Base
    attr_reader :cname_record

    def call
      result = CnameRecords::CreateAPIGatewayDomain.call(cname_record)
      cname_record = result&.fetch(:cname_record)

      trigger_cloudflare_worker = result&.fetch(:status) == :success && cname_record&.internal?
      if trigger_cloudflare_worker
        CnameRecords::CreateCloudflareRecord.call(cname_record)
      else
        cname_record.cname_record_created!
      end
    end
  end
end
