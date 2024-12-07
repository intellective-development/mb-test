class ConsumerAPIV2::Entities::GiftCardTheme < Grape::Entity
  # This class is used in product_grouping_store_view.rb
  # We might need to migrate PG entity to this and use only this class in the GC endpoint when this grows more
  expose :name
  expose :display_name
  expose :theme_image_url
  expose :thumb_image_url
end
