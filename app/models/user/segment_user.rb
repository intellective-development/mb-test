class User
  module SegmentUser
    extend ActiveSupport::Concern

    EXCLUDED_CATEGORIES = '(accessories|gift\ baskets|book\ a\ bartender|promotions|gift\ card|snacks\ \&\ more|mixers|unknown)'.freeze
    MAX_SEGMENT_REQUEST_SIZE = 32_000 # if we send more data than this they ignore our request

    included do
      after_commit :identify_segment_user
    end

    def segment_id
      Digest::SHA256.hexdigest(String(email).downcase)
    end

    def storefront_iterable_id(order = nil)
      account.uid.present? && !account.guest? ? account.uid : segment_serialized_email(order)
    end

    def as_segment_user
      {
        user_id: segment_id,
        traits: common_traits.merge(mini_bar_traits)
      }
    end

    def storefront_user_iterable_attrs
      common_traits.merge(storefront_traits)
    end

    def common_traits
      {
        name: "#{first_name} #{last_name}",
        email: email,
        corporate: corporate?,
        vip: vip?,
        top_shipping_addresses: top_shipping_addresses.map(&:as_segment_address),
        first_name: first_name,
        last_name: last_name,
        doorkeeper_application_name: doorkeeper_application&.name,
        phoneNumber: most_recently_used_phone_number,
        referral_code: referral_code,
        user_created_at: created_at&.strftime(Segments::SegmentService::TIME_FORMAT)
      }.merge(segment_serialized_orders)
        .merge(segment_serialized_last_used_address)
    end

    def mini_bar_traits
      {
        available_shipping_method: shipping_addresses.flat_map(&:available_shipping_methods)&.map(&:shipping_type)&.uniq,
        regions: segment_serialized_regions,
        zip_codes: shipping_addresses.pluck(:zip_code).uniq,
        minibar_user: true
      }.merge(segment_serialized_order_preferences)
    end

    def storefront_traits
      {
        storefront_id: account.storefront.id,
        storefront_name: account.storefront.name,
        storefront_pim_name: account.storefront.pim_name
      }
    end

    def most_recently_used_phone_number
      last_order = orders.order(created_at: :asc).joins(:ship_address).where.not(addresses: { phone: nil }).last
      if last_order
        last_order.ship_address.normalized_phone
      else
        addresses.where.not(phone: nil).order(created_at: :asc).last&.normalized_phone
      end
    end

    private

    def top_shipping_addresses
      shipping_addresses.joins(:orders).merge(Order.finished).group(:id).order('count(orders.id) desc').first(5)
    end

    def segment_serialized_orders
      user_orders = orders.finished

      return {} if user_orders.empty?
      return { orders_count: user_orders.count } unless account.storefront.default_storefront?

      items = user_orders.flat_map(&:order_items)

      {
        average_item_count: user_orders.map(&:order_items).map(&:count).sum.fdiv(user_orders.count),
        average_item_value: items.map(&:total).sum.fdiv(items.count),
        average_order_value: user_orders.map(&:taxed_total).sum.fdiv(user_orders.count),
        first_order_date: user_orders.order(completed_at: :asc).first&.completed_at&.strftime(Segments::SegmentService::TIME_FORMAT),
        gift_percentage: user_orders.where.not(gift_detail_id: nil).count.fdiv(user_orders.count),
        last_supplier_id: last_supplier&.id || last_supplier&.first&.id,
        latest_order_date: user_orders.order(completed_at: :desc).first&.completed_at&.strftime(Segments::SegmentService::TIME_FORMAT),
        orders_count: user_orders.count,
        total_spend: user_orders.map(&:taxed_total).sum
      }
    end

    def segment_serialized_order_preferences
      user_orders = orders.finished

      return {} if user_orders.empty?

      sql_top = lambda do |relation, model|
        model_relations = if relation == :product_size_groupings
                            [{ product_size_groupings: :hierarchy_category }, :order_items]
                          elsif %i[brands shipping_methods].include?(relation)
                            [{ product_size_groupings: :hierarchy_category }, :order_items, relation]
                          else
                            [relation, :order_items]
                          end
        user_orders
          .finished
          .joins(model_relations)
          .where('product_types.name !~* ?', EXCLUDED_CATEGORIES)
          .group("#{model}.id")
          .order('sum(order_items.quantity) desc')
          .limit(5)
          .pluck("#{model}.name")
      end
      top_categories = sql_top.call(:hierarchy_categories, :product_types)
      top_types      = sql_top.call(:hierarchy_types, :product_types)
      top_subtypes   = sql_top.call(:hierarchy_subtypes, :product_types)
      top_groupings  = sql_top.call(:product_size_groupings, :product_groupings)
      top_brands     = sql_top.call(:brands, :brands)

      top_shipping_method = sql_top.call(:shipping_methods, :shipping_methods)[0]

      {
        top_purchased_brands: top_brands,
        top_purchased_categories: top_categories,
        top_purchased_product_groupings: top_groupings,
        top_purchased_subtypes: top_subtypes,
        top_purchased_types: top_types,
        regions: profile&.order_regions&.present? && Region.where(id: profile.order_regions).pluck(:name),
        sent_gifts: user_orders.where.not(gift_detail_id: nil).exists?,
        top_address: top_shipping_addresses.first&.as_segment_address,
        top_brand: top_brands[0],
        top_category: top_categories[0],
        top_delivery_method: top_shipping_method,
        top_product_grouping: top_groupings[0],
        top_region: profile&.top_region && Region.find_by(id: profile.top_region)&.name,
        top_subtype: top_subtypes[0],
        top_type: top_types[0]
      }
    end

    def segment_serialized_last_used_address
      last_address = orders.where.not(state: ['in_progress', nil]).order(created_at: :desc).first&.ship_address
      return {} unless last_address.present?

      {
        last_zip_code: last_address.zip_code,
        last_address_1: last_address.address1,
        last_address_2: last_address.address2,
        last_city: last_address.city,
        last_state: last_address.state_name
      }
    end

    def segment_serialized_regions
      shipments.map do |shipment|
        shipment.supplier&.region&.name
      end.compact.uniq
    end

    def identify_segment_user
      SegmentIdentifyWorker.perform_async(id)
    end

    def segment_serialized_email(order)
      return email if order.nil?

      guest_by_email? ? order.email : email
    end
  end
end
