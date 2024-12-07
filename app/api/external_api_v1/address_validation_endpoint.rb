require 'ostruct'

class ExternalAPIV1::AddressValidationEndpoint < BaseAPIV1
  include ShipEngineAdapter::Requests

  format :json
  version 'v1', using: :path
  prefix 'api/external'

  helpers AuthenticateWithApiKey

  helpers do
    def address_ostruct_params
      {
        address1: params[:address1],
        city: params[:city],
        state_name: params[:state],
        zip_code: params[:zip_code]
      }
    end

    def address_validation_result(status:, matched_address:, error_messages:)
      OpenStruct.new(status: status, matched_address: matched_address, error_messages: error_messages)
    end

    def ship_engine_adapter
      @ship_engine_adapter ||= ShipEngineAdapter.new
    end
  end

  desc 'Validates address via ShipEngine'
  params do
    requires :address1,   type: String, allow_blank: false
    requires :city,       type: String, allow_blank: false
    requires :state,      type: String, allow_blank: false
    requires :zip_code,   type: String, regexp: /^(\d){5}/
  end
  post :validate_address do
    address = OpenStruct.new(address_ostruct_params)

    begin
      res = ship_engine_adapter.validate_address(address: address)
    rescue ValidateAddress::AddressUnverifiedError, ValidateAddress::AddressWarningError, ValidateAddress::AddressError => e
      status 200
      present address_validation_result(
        status: e.resp_body.fetch('status'),
        matched_address: nil,
        error_messages: e.resp_body.fetch('messages').map { |m| m['message'] }.join(', ')
      ), with: ExternalAPIV1::Entities::AddressValidationResult
      return
    end

    status 200
    present address_validation_result(
      status: 'verified',
      matched_address: res.fetch('matched_address'),
      error_messages: []
    ), with: ExternalAPIV1::Entities::AddressValidationResult
  end
end
