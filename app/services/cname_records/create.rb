# frozen_string_literal: true

module CnameRecords
  # CnameRecords::Create
  class Create < BaseService
    attr_reader :params, :errors, :cname_record

    def initialize(params = {}) # rubocop:disable Lint/MissingSuper
      @params = params.dup
      @errors = nil
    end

    def call
      CnameRecord.transaction do
        initialize_cname_record

        CnameRecords::ClearConfig.call(cname_record) if cname_record.persisted? && cname_record.domain != params[:domain]

        cname_record.update!(domain: params[:domain], status: :pending)
      rescue ActiveRecord::RecordInvalid => e
        @errors = e.message
        raise ActiveRecord::Rollback
      end

      error!('Invalid domain!') unless cname_record.internal?

      if errors.blank?
        create_custom_domain
      else
        error!(errors)
      end
    end

    private

    def create_custom_domain
      CnameRecords::CreateCustomDomain.call(cname_record)

      { status: :success, data: @cname_record }
    rescue StandardError => e
      error!(e.message)
    end

    def error!(message)
      { status: :error, message: message }
    end

    def initialize_cname_record
      @cname_record = CnameRecord.find_or_initialize_by(storefront_id: params[:storefront_id])
    end
  end
end
