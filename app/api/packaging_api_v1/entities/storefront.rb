class PackagingAPIV1::Entities::Storefront < Grape::Entity
  expose :name
  expose :button_color
  expose :google_tag_id
  expose :hostname
  expose :favicon_url
  expose :logo_url
  expose :mobile_logo_url
  expose :segment_tag_id
  expose :home_url
  expose :footer_copy
  expose :support_email
  expose :support_phone_number
  expose :tracking_page_hostname
  expose :storefront_links, with: PackagingAPIV1::Entities::Storefront::StorefrontLink
  expose :storefront_fonts
  expose :digital_packing_slip_placements, with: PackagingAPIV1::Entities::Storefront::DigitalPackingSlipPlacement do |storefront|
    if storefront.inherits_tracking_page
      storefront.parent_storefront.digital_packing_slip_placements
    else
      storefront.digital_packing_slip_placements
    end
  end

  private

  def button_color
    object.inherits_tracking_page ? object.parent_storefront.button_color : object.button_color
  end

  def mobile_logo_url
    object.inherits_tracking_page ? object.parent_storefront.mobile_logo_url : object.mobile_logo_url
  end

  def logo_url
    object.inherits_tracking_page ? object.parent_storefront.logo_url : object.logo_url
  end

  def storefront_fonts
    if object.inherits_tracking_page
      PackagingAPIV1::Entities::Storefront::StorefrontFont.represent(object.parent_storefront.storefront_fonts).as_json
    else
      PackagingAPIV1::Entities::Storefront::StorefrontFont.represent(object.storefront_fonts).as_json
    end
  end
end
