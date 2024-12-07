class User
  module ProfileData
    def profile_data
      load_orders
      load_order_items
      load_products
      load_recent_products
      load_regions

      {
        min_price: @order_items.empty? ? 0 : @order_items.first.price.to_f.round_at(2),
        max_price: @order_items.empty? ? 0 : @order_items.last.price.to_f.round_at(2),
        ordered_types: @product_groupings.map { |p| p.hierarchy_type&.id }.reject(&:blank?).uniq,
        ordered_categories: @product_groupings.map { |p| p.hierarchy_category&.id }.reject(&:blank?).uniq,
        ordered_subtypes: @product_groupings.map { |p| p.hierarchy_subtype&.id }.reject(&:blank?).uniq,
        recently_ordered_types: @recent_product_groupings.map { |p| p.hierarchy_type&.id }.reject(&:blank?).uniq,
        recently_ordered_categories: @recent_product_groupings.map { |p| p.hierarchy_category&.id }.reject(&:blank?).uniq,
        recently_ordered_subtypes: @recent_product_groupings.map { |p| p.hierarchy_subtype&.id }.reject(&:blank?).uniq,
        most_ordered_types: most_popular(:hierarchy_type),
        most_ordered_categories: most_popular(:hierarchy_category),
        most_ordered_subtypes: most_popular(:hierarchy_subtype),
        most_popular_category: most_popular_category, # Mailchimp + PZN
        most_popular_type: @product_types.uniq.max_by { |i| @product_types.count(i) },
        order_regions: @shipments.map { |shipment| shipment.supplier.region.id if shipment.supplier&.region }.uniq.compact, # Mailchimp
        top_region: @regions.empty? ? nil : top_region, # Mailchimp
        last_region: @regions.empty? ? nil : last_region, # Mailchimp
        last_full_update: Time.zone.now
      }
    end

    private

    RECENT_PRODUCTS_CUTOFF = 60.days

    def load_orders
      @orders ||= orders.finished
                        .includes(:order_amount, suppliers: [:region], order_items: [variant: [product_size_grouping: %i[product_type hierarchy_type hierarchy_category hierarchy_subtype]]])
                        .order(:completed_at)

      @shipments = @orders.flat_map(&:shipments)
    end

    def load_order_items
      @order_items ||= @orders.flat_map { |o| o.order_items.sort_by(&:price) }
    end

    def load_products
      @product_groupings ||= @order_items.flat_map { |oi| oi.variant&.product_size_grouping }.compact
      @product_types ||= @product_groupings.map { |p| p.product_type&.id }.compact
    end

    def load_recent_products
      @recent_product_groupings ||= @order_items.flat_map { |oi| oi.variant&.product_size_grouping if oi.created_at > RECENT_PRODUCTS_CUTOFF.ago }.compact
    end

    def load_regions
      @regions ||= @orders.flat_map { |order| order.suppliers.map(&:region) }.compact
    end

    def top_region
      @regions.group_by(&:itself).values.max_by(&:size).first.id
    end

    def last_region
      return nil if @orders.empty?

      last_supplier = @orders.last.suppliers.first
      last_supplier&.region&.id
    end

    def most_popular_category
      ordered_categories = @product_groupings.collect { |p| p.hierarchy_category&.id }.reject(&:blank?).uniq
      ordered_categories.max_by { |i| ordered_categories.count(i) }
    end

    def most_popular(key)
      return [] unless @product_groupings

      popular_by_key = @product_groupings.group_by(&key).sort_by { |_k, v| v.size }.reverse # we want popularity descending
      popular_key_ids = popular_by_key.map { |k, _v| k&.id }.compact # map to the ids of whatever key we chose
      popular_key_ids.slice(0, 3) # return the top 3 most popular key ids
    end
  end
end
