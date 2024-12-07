class SupplierAPIV3::ShipmentsEndpoint::KeywordEndpoint < BaseAPIV3
  helpers do
    params :search do
      optional :query, type: String, default: '*', coerce_with: ->(val) { val.blank? ? '*' : val.slice(0, 255) }
    end

    params :filtering do
      optional :filters, type: Hash, default: {}
    end

    def get_keywords(params, type)
      shipments = Shipment.search(params[:query], Shipment::QueryBuilder.new(params.dup, current_supplier_ids, type).query)
      keywords = []
      shipments.each do |shipment|
        query = params[:query]&.downcase
        shipment.order_items.each do |item|
          name = item.product_trait_name
          keywords.push({ keyword: name, key: 'Product Name' }) if name&.downcase&.include?(query)
        end

        shipment.custom_tags.each do |tag|
          name = tag.name
          keywords.push({ keyword: name, key: 'Custom Tag' }) if name&.downcase&.include?(query)
        end

        keywords.push({ keyword: shipment.user.first_name, key: 'First Name' }) if shipment.user.first_name.downcase.include?(query)
        keywords.push({ keyword: shipment.user.last_name, key: 'Last Name' }) if shipment.user.last_name.downcase.include?(query)
        keywords.push({ keyword: shipment.gift_detail&.recipient_name, key: 'Gift Recipient' }) if shipment.gift_detail&.recipient_name&.downcase&.include?(query)
        keywords.push({ keyword: shipment.order_number, key: 'Order Number' }) if shipment.order_number.downcase.include?(query)
        keywords.push({ keyword: shipment.order.storefront.name, key: 'Storefront Name' }) if shipment.order.storefront.name.downcase.include?(query)
      end
      keywords
    end
  end

  namespace :orders do
    namespace :keywords do
      desc 'Retrieve a list of keywords.'
      params do
        use :search
        use :filtering
      end
      get do
        present get_keywords(params, :all).uniq
      end

      desc 'Retrieve a list of keywords for completed orders.'
      params do
        use :search
        use :filtering
      end
      get :completed do
        present get_keywords(params, :completed).uniq
      end

      desc 'Retrieve a list of keywords of todays orders and unconfirmed orders from other days.'
      params do
        use :search
        use :filtering
      end
      get :today do
        present get_keywords(params, :today).uniq
      end

      desc 'Retrieve a list of keywords of scheduled.'
      params do
        use :search
        use :filtering
      end
      get :scheduled do
        present get_keywords(params, :scheduled).uniq
      end

      desc 'Retrieve a list of keywords of shipping.'
      params do
        use :search
        use :filtering
      end
      get :shipping do
        present get_keywords(params, :shipping).uniq
      end

      desc 'Retrieve a list of keywords of pre_sale.'
      params do
        use :search
        use :filtering
      end
      get :pre_sale do
        present get_keywords(params, :pre_sale).uniq
      end

      desc 'Retrieve a list of keywords of back_order.'
      params do
        use :search
        use :filtering
      end
      get :back_order do
        present get_keywords(params, :back_order).uniq
      end

      desc 'Retrieve a list of keywords of exception.'
      params do
        use :search
        use :filtering
      end
      get :exception do
        present get_keywords(params, :exception).uniq
      end
    end
  end
end
