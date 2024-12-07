class AfterShip::CreateTrackingService
  class UnrecognizedCarrierError < StandardError; end

  attr_reader :error_message

  def initialize(package, should_create_shipment_comment = false)
    raise ArgumentError.new, 'Package cannot be nil' if package.nil?

    @package = package
    @should_create_shipment_comment = should_create_shipment_comment
  end

  def call
    resp_body = call_after_ship
    set_package_carrier_and_tracking_url(resp_body)
    create_after_ship_tracking(resp_body)
    send_shipment_processed_segment_event
    create_shipment_comment
  rescue AfterShipAdapter::UnsuccessfulResponseError, UnrecognizedCarrierError => e
    @error_message = e.message
    note = "Error creating tracking on AfterShip for a package with tracking number #{package.tracking_number} associated with shipment #{package.shipment.id}. Here's the error: \n#{e}"
    package.shipment.comments.create(note: note)
    Rails.logger.error note

    false
  end

  private

  attr_reader :package, :should_create_shipment_comment

  def call_after_ship
    after_ship_adapter.create_tracking(package: package)
  end

  def set_package_carrier_and_tracking_url(resp_body)
    slug = resp_body.fetch('data').fetch('tracking').fetch('slug')

    raise UnrecognizedCarrierError, 'We could not recognize the carrier. Please check the tracking number that you provided.' if unrecognized_carrier?(slug)

    package.update(
      carrier: slug,
      tracking_url: "#{Package::RB_TRACKING_PAGE_BASE_URL}/#{package.tracking_number}"
    )
  end

  def create_after_ship_tracking(resp_body)
    package.create_after_ship_tracking(after_ship_tracking_id: resp_body.fetch('data').fetch('tracking').fetch('id'))
  end

  def send_shipment_processed_segment_event
    Shipment::SendShipmentProcessedEventService.new(package: package).call
  end

  def create_shipment_comment
    return unless should_create_shipment_comment

    package.shipment.comments.create(note: "Tracking URL: #{package.tracking_url}") if package.after_ship_tracking.present?
  end

  def after_ship_adapter
    @after_ship_adapter ||= AfterShipAdapter.new
  end

  def unrecognized_carrier?(slug)
    slug == 'unrecognized'
  end
end
