class AdminAPIV1::InventoryEndpoint < BaseAPIV1
  require 'json'
  format :json
  content_type :json, 'application/json'

  MAX_SKU_LIST_SIZE = 500

  namespace :inventory do
    desc 'Endpoints for Inventory App data retrieval and comparison'

    route_param :supplier_id, scopes: [:simple_auth] do
      before do
        authenticate_with_token!(ENV['INVENTORY_AUTH_TOKEN'])
        @supplier = Supplier.find(params[:supplier_id])
      end

      namespace :sku_diff do
        desc 'SKU list diffing tool for Inventory App'
        params do
          requires :skus, type: Array[String], desc: "List of SKUs to compare to supplier's variants"
        end
        post do
          error!("Maximum number of SKU's exceeded (#{MAX_SKU_LIST_SIZE})") if params[:skus].size > MAX_SKU_LIST_SIZE
          supplier_skus = @supplier.variants.active.pluck(:sku)
          overlap = supplier_skus & params[:skus]
          present :overlap, overlap.to_json
        end
      end

      namespace :supplier_products do
        desc 'List of products for inventory import to identify incoming products'
        get do
          # TODO: complete variant details in elasticsearch (sku, size, state...) & fetch from there
          # variants = Variant.search(
          #   load:false, # We do not want to load the ActiveRecords from database
          #   body: {
          #     query: {
          #       term: {
          #         "supplier_id" => {
          #           value: @supplier.id
          #         }
          #       }
          #     }
          #   }
          # ).hits.map...
          products = Variant.includes(:inventory, product: [product_size_grouping: :brand])
                            .where(supplier_id: @supplier.id)
                            .pluck('variants.sku',
                                   'brands.name',
                                   'product_groupings.name',
                                   'products.upc',
                                   'products.container_type',
                                   'products.container_count',
                                   'products.volume_unit',
                                   'products.volume_value',
                                   'variants.deleted_at',
                                   'products.state',
                                   'products.permalink',
                                   'variants.price',
                                   'inventories.count_on_hand')
                            .map do |(sku, brand_name, name, upc, container_type, container_count, volume_unit, volume_value, deleted_at, state, permalink, price, quantity)|
            {
              sku: sku,
              brand_name: brand_name,
              name: name,
              upc: upc,
              volume: {
                container_type: container_type,
                container_count: container_count,
                volume_unit: volume_unit,
                volume_value: volume_value
              },
              variant_state: deleted_at ? 'inactive' : 'active',
              product_state: state,
              permalink: permalink,
              price: price,
              quantity: quantity
            }
          end
          present :products, products
        end
      end

      namespace :supplier_stats do
        desc "Supplier's current inventory statistics"
        get do
          present :statistics, @supplier, with: AdminAPIV1::Entities::Inventory::SupplierStats
        end
      end
    end

    namespace :supplier_options do
      desc 'List of Suppliers and active state'
      get do
        # TODO: Consider Pagination here....
        present :suppliers, Supplier.includes(:region).all.order(:name), with: AdminAPIV1::Entities::Inventory::SupplierOption
      end
    end
  end
end
