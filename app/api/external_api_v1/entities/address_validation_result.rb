class ExternalAPIV1::Entities::AddressValidationResult < Grape::Entity
  expose :status
  expose :matched_address
  expose :error_messages
end
