module ProductPriorityScope
  extend ActiveSupport::Concern

  VOLUME_ORDER = ['12oz', '11.2oz', '16oz', '24oz', '750ml', '720ml', '1L', '1.75L', '1.5L', '375ml'].freeze
  PACK_SIZE_ORDER = ['6 pack', '4 pack', '12 pack', '24 pack', '30 pack', '2 pack'].freeze

  included do
    scope :order_by_volume, lambda {
      order_by_volume = VOLUME_ORDER.map do |value|
        "#{table_name}.short_volume='#{value}' desc nulls last"
      end
      order_by_pack_size = PACK_SIZE_ORDER.map do |value|
        "#{table_name}.short_pack_size='#{value}' desc nulls last"
      end
      order(Arel.sql(order_by_volume.concat(order_by_pack_size).concat(["#{table_name}.item_volume"]).join(', ')))
    }
  end
end
