class ZipcodeCoveredPromotionWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options \
    queue: 'sync_profile',
    retry: true,
    lock: :until_executing

  def perform_with_error_handling(params)
    User.where(id: get_covered_user_ids(params['delivery_zone_id'])).find_each do |user|
      Segments::SegmentService.from(user.account.storefront).zipcode_covered_event(user, params['promotion_type'])
    end
  end

  def get_covered_user_ids(delivery_zone_id)
    return [] unless (zone = DeliveryZonePolygon.find_by_id(delivery_zone_id))

    zipcodes = zone.overlapped_zipcodes + zone.contained_zipcodes
    covered = Address.active
                     .shipping
                     .within_zipcodes(zipcodes)
                     .within_delivery_zone(zone.id)
    covered.pluck('distinct(addresses.addressable_id)')
  end
end
