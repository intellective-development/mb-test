# frozen_string_literal: true

class AdminAPIV1
  # AdminAPIV1::CnameRecordsEndpoint
  class CnameRecordsEndpoint < BaseAPIV1
    namespace :cname_records do
      helpers AuthenticateWithToken
      before { authenticate_with_token!(ENV['BAR_OS_AUTH_TOKEN']) }

      desc 'Get CNAME Setup status'
      get ':id' do
        cname_record = CnameRecord.find(params[:id])
        present cname_record, with: AdminAPIV1::Entities::CnameRecord
      rescue ActiveRecord::RecordNotFound
        error!('Could not find a CNAME Record to the given ID', 404) unless cname_record
      end

      desc 'Queue up the domain creation domain'
      params do
        requires :domain
        requires :storefront_id
      end
      post do
        result = CnameRecords::Create.call(params)
        present result[:data], with: AdminAPIV1::Entities::CnameRecord
      end
    end
  end
end
