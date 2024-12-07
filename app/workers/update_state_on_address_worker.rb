class UpdateStateOnAddressWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 5,
                  queue: :backfill,
                  lock: :until_and_while_executing

  def perform_with_error_handling(_arg_)
    Address.where(state: nil).each do |address|
      address.state = State.find_by(name: GoogleMapApi.new(address).state&.name)
      address.save
    end
  end

  class GoogleMapApi
    AddressComponent = Struct.new(:name, :abbreviation, :types)
    GOOGLE_MAPS_API_URL = "https://maps.googleapis.com/maps/api/geocode/json?sensor=true&key=#{ENV['GOOGLE_MAPS_API_KEY']}".freeze

    def initialize(address)
      @address = address
    end

    def state
      @state ||= address_components&.find { |element| element.types.include?('administrative_area_level_1') }
    end

    private_constant :GOOGLE_MAPS_API_URL, :AddressComponent

    private

    attr_reader :address

    def connection
      @connection ||= Faraday.new(url: url_by_zip_code) do |faraday|
        faraday.adapter Faraday.default_adapter
        faraday.response :json
      end
    end

    def address_components
      return if results.blank?

      results.first['address_components']
             .map { |comp| AddressComponent.new(comp['long_name'], comp['short_name'], comp['types']) }
    end

    def results
      @resutls ||= connection.get.body['results']
    end

    def url_by_zip_code
      GOOGLE_MAPS_API_URL + "&address=#{address.zip_code}"
    end
  end

  private_constant :GoogleMapApi
end
