class PackagingAPIV1::StorefrontEndpoint::DigitalPackingSlipPlacementsEndpoint < PackagingAPIV1
  namespace :storefront do
    namespace :digital_packing_slip_placements do
      desc 'Get all digital packing slip placements for the current storefront.'
      get do
        @digital_packing_slip_placements = if storefront.inherits_tracking_page
                                             storefront.parent_storefront.digital_packing_slip_placements
                                           else
                                             storefront.digital_packing_slip_placements
                                           end

        status 200
        present @digital_packing_slip_placements, with: PackagingAPIV1::Entities::Storefront::DigitalPackingSlipPlacement
      end
    end
  end
end
