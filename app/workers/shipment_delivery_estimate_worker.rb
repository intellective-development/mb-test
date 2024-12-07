class ShipmentDeliveryEstimateWorker
  include Sidekiq::Worker
  include WorkerErrorHandling
  include SentryNotifiable

  require 'google_distance_matrix'

  sidekiq_options retry: false,
                  queue: 'internal',
                  lock: :until_and_while_executing

  # TODO: Put in a service!
  # TODO: Incorporate feedback - if we can get actual delivery time, or if this
  # estimate was under, then we can compensate during the process.
  # TODO: Per-Shipment overridable delivery modes.

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.includes(:metadata, order: [:ship_address], supplier: %i[address profile]).find(shipment_id)
    shipment.create_metadata unless shipment.metadata

    # no estimating for digital shipments
    return if shipment.digital?
    # No point estimating if we don't have our addresses geocoded
    return unless shipment.supplier.address.geocoded? && shipment.order.ship_address&.geocoded?

    configure

    matrix = GoogleDistanceMatrix::Matrix.new
    matrix.configure do |config|
      config.mode = shipment.supplier.profile.delivery_mode
      config.google_api_key = ENV['GOOGLE_MAPS_API_KEY']

      # TODO: Be smarter at estimating this - we should ensure supplier is
      # currently open and account for average confirmation time, current
      # backlog of orders, waiting at destination.
      # TODO: Do we want to consider calculating or refreshing this on
      # confirmation rather than order placed?
      config.departure_time = ((shipment.scheduled_for || Time.zone.now) + 25.minutes).to_i
    end

    origin = GoogleDistanceMatrix::Place.new(lng: shipment.supplier.address.longitude, lat: shipment.supplier.address.latitude)
    destination = GoogleDistanceMatrix::Place.new(lng: shipment.order.ship_address&.longitude, lat: shipment.order.ship_address&.latitude)

    matrix.origins << origin
    matrix.destinations << destination

    begin
      data = matrix.data.dig(0, 0)

      # Check if things came back successfully.
      return unless data&.status == 'ok'

      shipment.metadata.distance = data.distance_in_meters
      shipment.metadata.delivery_estimate = data.duration_in_seconds

      # TODO: Account for OOH orders.
      shipment.metadata.estimated_delivered_at = ((shipment.scheduled_for || Time.zone.now) + 25.minutes) + Integer(data.duration_in_seconds).seconds
      shipment.metadata.save
    rescue GoogleDistanceMatrix::ClientError => e
      message_sentry_and_log(e.message)

      shipment.metadata = shipment.order.ship_address&.distance_to(shipment.supplier.address)
      shipment.metadata.save
    end
  end

  private

  def configure
    GoogleDistanceMatrix.configure_defaults do |config|
      config.cache = ActiveSupport::Cache.lookup_store :mem_cache_store, expires_in: 12.hours
    end
  end
end
