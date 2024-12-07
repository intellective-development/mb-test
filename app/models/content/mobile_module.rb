# == Schema Information
#
# Table name: content_mobile_modules
#
#  id                       :integer          not null, primary key
#  internal_name            :string(255)      not null
#  module_type              :integer          not null
#  priority                 :integer          default(0)
#  logged_in                :boolean          default(TRUE), not null
#  logged_out               :boolean          default(FALSE), not null
#  config                   :json
#  created_at               :datetime
#  updated_at               :datetime
#  content_mobile_screen_id :integer
#  section_id               :string
#

class Content::MobileModule < ActiveRecord::Base
  enum module_type: {
    carousel: 0,
    product_scroller: 1,
    image_scroller: 2,
    product_type_scroller: 3,
    product_banner: 4,
    product: 5,
    text_block: 6,
    brand_description: 7,
    image_gallery: 8,
    shipping_required_notification: 9,
    link_list: 11,
    product_type_link_list: 12,
    navigation_category: 13,
    column_layout: 14,
    image_grid: 15,
    text_carousel: 16,
    product_video: 17,
    previous_orders: 18,
    cocktail_scroller: 19,
    app_download: 20,
    product_cocktail_and_video_scroller: 21,
    order_complete_carousel: 22
  }

  belongs_to :screen, class_name: 'Content::MobileScreen', foreign_key: 'content_mobile_screen_id', inverse_of: 'modules'

  validates :internal_name, presence: true, uniqueness: true
  before_save :parse_config_to_json

  scope :priority_order,  -> { order(:section_id, priority: :asc) }
  scope :logged_in,       -> { where(logged_in:  true) }
  scope :logged_out,      -> { where(logged_out: true) }

  module_types.each do |type|
    define_method "generate_#{type[0]}_config" do |_context = {}|
      { error: 'Not Implemented' }
    end
  end

  # TODO: The next ~60 lines can be replaced by more metaprogramming!
  def generate_product_type_scroller_config(context)
    Content::ProductTypeScroller.new(merge_options(context)).config
  end

  def generate_product_type_link_list_config(context)
    Content::ProductTypeLinkList.new(merge_options(context)).config
  end

  def generate_image_scroller_config(context)
    Content::ImageScroller.new(merge_options(context)).config
  end

  def generate_product_banner_config(context)
    Content::ProductBanner.new(merge_options(context)).config
  end

  def generate_product_config(context)
    Content::Product.new(merge_options(context)).config
  end

  def generate_carousel_config(context)
    Content::Carousel.new(merge_options(context)).config
  end

  def generate_text_carousel_config(context)
    Content::TextCarousel.new(merge_options(context)).config
  end

  def generate_product_scroller_config(context)
    Content::ProductScroller.new(merge_options(context)).config
  end

  def generate_cocktail_scroller_config(context)
    Content::CocktailScroller.new(merge_options(context)).config
  end

  def generate_text_block_config(context)
    Content::TextBlock.new(merge_options(context)).config
  end

  def generate_brand_description_config(context)
    Content::BrandDescription.new(merge_options(context)).config
  end

  def generate_image_gallery_config(context)
    Content::ImageGallery.new(merge_options(context)).config
  end

  def generate_shipping_required_notification_config(context)
    Content::ShippingRequiredNotification.new(merge_options(context)).config
  end

  def generate_link_list_config(context)
    Content::LinkList.new(merge_options(context)).config
  end

  def generate_navigation_category_config(context)
    Content::NavigationCategory.new(merge_options(context)).config
  end

  def generate_column_layout_config(context)
    Content::ColumnLayout.new(merge_options(context)).config
  end

  def generate_image_grid_config(context)
    Content::ImageGrid.new(merge_options(context)).config
  end

  def generate_product_video_config(context)
    Content::ProductVideo.new(merge_options(context)).config
  end

  def generate_previous_orders_config(context)
    Content::PreviousOrders.new(merge_options(context)).config
  end

  def generate_app_download_config(context)
    Content::AppDownload.new(merge_options(context)).config
  end

  def generate_product_cocktail_and_video_scroller_config(context)
    Content::ProductCocktailAndVideo.new(merge_options(context)).config
  end

  def generate_order_complete_carousel_config(context)
    Content::OrderCompleteCarousel.new(merge_options(context)).config
  end

  private

  def merge_options(context)
    config.merge(context.opts_hash).symbolize_keys
  end

  def get_suppliers(ids)
    # TODO: What do we do if someone passes an invalid supplier id
    @suppliers ||= Supplier.includes(:profile).where(id: ids)
  end

  def url_base
    @url_base = ENV['ASSET_HOST'] || 'https://minibardelivery.com'
  end

  def parse_config_to_json
    self.config = JSON.parse(config) if config.present? && config.is_a?(String) && config.include?('{')
  end
end
