class StorefrontPaymentInformationService
  attr_reader :company_name, :address1, :address2, :location

  def initialize(company_name:, address1:, address2:, location:)
    @company_name = company_name
    @address1 = address1
    @address2 = address2
    @location = location
  end

  def self.minibar
    new(
      company_name: 'ReserveBar Express Corp.',
      address1: '426 Main Street',
      address2: 'Suite F',
      location: 'Ridgefield, CT 06877'
    )
  end

  def self.reservebar
    new(
      company_name: 'ReserveBar Holdings Corp.',
      address1: '426 Main Street',
      address2: 'Suite F',
      location: 'Ridgefield, CT 06877'
    )
  end
end
