# frozen_string_literal: true

module CnameRecords
  # CnameRecords::CreateCloudflareRecord
  class CreateCloudflareRecord < Base
    CLOUDFLARE_TOKEN = ENV['CLOUDFLARE_TOKEN'].freeze
    RECORD_TYPE = 'CNAME'

    def call
      cname_record.creating_cname_record!

      CnameRecord.transaction do
        Cloudflare.connect(token: CLOUDFLARE_TOKEN) do |connection|
          zone = connection.zones.find_by_name(cname_record.zone) # rubocop:disable Rails/DynamicFindBy
          raise "Unable to find a zone to the domain: #{cname_record.zone}" if zone.blank?

          existing_cname = zone.dns_records.find_by_name(cname_record.domain) # rubocop:disable Rails/DynamicFindBy
          create_cname(zone) unless existing_cname && existing_cname.type == RECORD_TYPE
        rescue StandardError => e
          @errors = e
        end

        raise @errors if @errors.present?

        cname_record.cname_record_created!
      end
    end

    private

    def create_cname(zone)
      zone.dns_records.create(
        RECORD_TYPE,
        cname_record.domain,
        cname_record.api_gateway_domain
      )
    end
  end
end
