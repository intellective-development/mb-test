# frozen_string_literal: true

module Admin
  module Storefronts
    # Admin::Storefronts::CnameRecordsController
    class CnameRecordsController < Admin::BaseController
      before_action :set_cname_record, only: :index

      def index; end

      def create
        result = CnameRecords::Create.call(cname_record_params)

        if result[:status] == :success
          redirect_to admin_storefront_cname_records_path(params[:storefront_id])
        else
          set_cname_record(cname_record_params)
          @errors = result[:message]
          render :index
        end
      end

      def verify_ssl
        CnameRecords::VerifySslCertificationWorker.perform_async(params[:id])

        redirect_to admin_storefront_cname_records_path(params[:storefront_id])
      end

      private

      def cname_record_params
        params
          .require(:cname_record)
          .permit(:domain)
          .merge(storefront_id: params[:storefront_id])
      end

      def set_cname_record(custom_params = {})
        @cname_record = CnameRecord.find_by(storefront_id: params[:storefront_id]) || CnameRecord.new(custom_params)
      end
    end
  end
end
