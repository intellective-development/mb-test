class ConsumerAPIV2::DeliverabilityEndpoint < BaseAPIV2
  helpers Shared::Helpers::AddressParamHelpers

  desc 'Checks deliverability of a given address address.', ConsumerAPIV2::DOC_AUTH_HEADER
  params do
    use :location
  end
  before do
    complete_address

    error!('No location provided.', 400) unless params[:address_id].present? || params[:coords].present? || params[:address].present?

    @address = Address.create_from_params(params)
    error! 'Address not found.', 500 if @address.nil?

    @address.geocode! unless @address.geocoded?
    error! 'Could not Geocode Address.', 500 unless @address.geocodable?

    error! 'Address is not a shipping address.', 500 unless @address.shipping?
  end
  get :deliverability do
    ls = LocationServices.new(@address)
    suppliers = ls.find_suppliers(storefront)

    present :deliverability, !suppliers.empty?
    status 200
  end
end
