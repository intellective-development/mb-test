require 'google/apis/content_v2_1'
require 'googleauth'

module Google
  class ShoppingContent
    # In charge of building the data and sending it to Google Shopping
    # Basically fills feeds (uploads inventory) and sets per-region data

    # Dev notes: We don't have sandbox project for this
    # Only production has the constants for AuthKey class

    SCOPE = 'https://www.googleapis.com/auth/content'.freeze
    MERCHANT_ID = '110905110'.freeze # MB Merchant ID, unlikely to change
    REGION_ID = '12349876'.freeze # NYS cities: New York,Albany,Buffalo,Rochester,Yonkers,Syracuse,New Rochelle,Cheektowaga
    FEED_ID = '216508285'.freeze # Supplementary feed
    ISO_8601_DATE = '%Y-%m-%d'.freeze
    REGULAR_DEFAULT_STOCK = (ENV['GOOGLE_SHOPPING_REGULAR_IN_STOCK'].to_s == 'true' ? 'in stock' : 'out of stock').freeze
    ADD_REGION_ID = ENV['GOOGLE_SHOPPING_ADD_REGION_ID'].to_s == 'true'

    class << self
      def client
        # https://github.com/googleapis/google-api-ruby-client/blob/master/generated/google-apis-content_v2_1/lib/google/apis/content_v2_1/service.rb
        # https://rubygems.org/gems/google-apis-content_v2_1
        # https://googleapis.dev/ruby/google-api-client/latest/Google/Apis/ContentV2_1.html
        client = Google::Apis::ContentV2_1::ShoppingContentService.new
        client.authorization = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: Google::AuthKey, scope: SCOPE)
        client.authorization.fetch_access_token!
        client
      end

      def build_products
        ActiveRecord::Base.connection.execute(PRODUCTS_SQL).to_a.select do |product|
          product['product_image_link'] || product['grouping_image_link']
        end
      end

      def upload_products(products)
        products.each_slice(1000).map do |products_batch|
          batch_request = []
          products_batch.each do |product|
            batch_request << {
              batchId: product['id'],
              merchantId: MERCHANT_ID,
              method: 'insert',
              product: product_to_google_spec(product)
            }
          end
          batch_object = Google::Apis::ContentV2_1::ProductsCustomBatchRequest.from_json({ entries: batch_request }.to_json)
          client.custombatch_product batch_object
        end
      end

      def supplementary_update_products(products)
        products.each_slice(1000).map do |products_batch|
          batch_request = []
          products_batch.each do |product|
            batch_request << {
              batchId: product['id'],
              merchantId: MERCHANT_ID,
              method: 'insert',
              product: product_to_google_spec(product),
              feedId: FEED_ID
            }
          end
          batch_object = Google::Apis::ContentV2_1::ProductsCustomBatchRequest.from_json({ entries: batch_request }.to_json)
          client.custombatch_product batch_object
        end
      end

      def refresh_google_products!
        # This only does NYS, we need work to make it to other states
        upload_products build_products
      end

      def refresh_supplementary_products_data!
        supplementary_update_products build_products
      end

      def refresh_google_regional_inventory!(in_stock = false)
        # You need to wait a long time (like 1h) before uploading regional inventory
        # Google takes a long time to process the product and if it does not exists, you will get an error
        build_products.each_slice(500).map do |batch|
          batch_upload_regional_inventory(batch, in_stock)
        end
      end

      def batch_upload_regional_inventory(products, in_stock)
        data = {
          entries: products.map { |p| batch_regional_inventory_entry(p, in_stock) }
        }
        google_object = Google::Apis::ContentV2_1::RegionalinventoryCustomBatchRequest.from_json data.to_json
        client.custombatch_regionalinventory google_object
      end

      def batch_regional_inventory_entry(product, in_stock)
        {
          batchId: product['id'],
          merchantId: MERCHANT_ID,
          method: 'insert',
          productId: "online:en:US:#{product['id']}",
          regionalInventory: regional_inventory_to_google_spec(product, REGION_ID, in_stock)
        }
      end

      def upload_product(product)
        google_spec = product_to_google_spec(product)
        if google_spec
          google_object = Google::Apis::ContentV2_1::Product.from_json google_spec.to_json

          client.insert_product(MERCHANT_ID, google_object)
        end
      end

      def upload_regional_inventory(product)
        google_spec = regional_inventory_to_google_spec(product, REGION_ID)
        if google_spec
          google_object = Google::Apis::ContentV2_1::RegionalInventory.from_json google_spec.to_json

          client.insert_regionalinventory(MERCHANT_ID, "online:en:US:#{product['id']}", google_object)
        end
      end

      def regional_inventory_to_google_spec(product, region_id, in_stock = false)
        data = {
          regionId: region_id,
          price: {
            value: product['price'],
            currency: 'USD'
          },
          availability: in_stock ? 'in stock' : 'out of stock',
          kind: 'content#regionalInventory'
        }
        if product['sale_price']
          data[:salePrice] = {
            value: product['sale_price'],
            currency: 'USD'
          }
        end
        data
      end

      def product_to_google_spec(product)
        # https://developers.google.com/shopping-content/reference/rest/v2.1/products
        # https://support.google.com/merchants/answer/7052112?visit_id=637546043320739285-472618995&rd=1#product_type

        google_product_category = Google::Category.get(product['category'], product['subtype'])

        data = {
          id: product['id'].to_s,
          offerId: product['id'].to_s,
          title: product['title'],
          description: product['description'],
          link: product['link'],
          imageLink: product['product_image_link'] || product['grouping_image_link'],
          # "additionalImageLinks": [string],
          contentLanguage: 'en',
          targetCountry: 'US',
          channel: 'online',
          expirationDate: 1.year.from_now.strftime(ISO_8601_DATE),
          adult: false,
          kind: 'content#product',
          brand: product['brand'],
          # "color": string,
          googleProductCategory: google_product_category,
          gtin: product['gtin'], # products.upc CHECK WITH ANDREW/ALEX
          itemGroupId: product['group_id'].to_s,
          # "material": string,
          # "mpn": string,
          # "pattern": string,
          price: {
            value: product['price'],
            currency: 'USD'
          },
          # "salePriceEffectiveDate": string,
          "shipping": [
            {
              "price": {
                value: product['shipping_price'],
                currency: 'USD'
              },
              "country": 'US',
              "region": 'NY'
              # "service": string,
              # "locationId": string,
              # "locationGroupName": string,
              # "postalCode": string,
              # "minHandlingTime": string,
              # "maxHandlingTime": string,
              # "minTransitTime": string,
              # "maxTransitTime": string
            }
          ],
          # "shippingWeight": { object (ProductShippingWeight) },
          # "sizes": [ string ], # S M L
          # "taxes": [ { object (ProductTax) } ],
          # "customAttributes": [{ object (CustomAttribute) } ],
          # "identifierExists": boolean,
          # "installment": { object (Installment) },
          # "loyaltyPoints": { object (LoyaltyPoints) },
          # "multipack": string,
          # "customLabel0": string,
          # "customLabel1": string,
          # "customLabel2": string,
          # "customLabel3": string,
          # "customLabel4": string,
          # "isBundle": boolean, CHECK WITH ALEX
          # "mobileLink": string,
          # "availabilityDate": string,
          "shippingLabel": 'shipped', # CHECK WITH ALEX
          # "unitPricingMeasure": {  object (ProductUnitPricingMeasure) },
          # "unitPricingBaseMeasure": {
          #   object (ProductUnitPricingBaseMeasure)
          # },
          # "shippingLength": {
          #   object (ProductShippingDimension)
          # },
          # "shippingWidth": {
          #   object (ProductShippingDimension)
          # },
          # "shippingHeight": {
          #   object (ProductShippingDimension)
          # },
          # "displayAdsId": string, CHECK WITH ALEX and below
          # "displayAdsSimilarIds": [
          #   string
          # ],
          # "displayAdsTitle": string,
          # "displayAdsLink": string,
          # "displayAdsValue": number,
          sellOnGoogleQuantity: product['stock'].to_s, # CHECK WITH ALEX
          # "promotionIds": [ CHECH WITH ALEX
          #   string
          # ],
          maxHandlingTime: '7', # CHECK WITH ALEX
          minHandlingTime: '3',
          # "costOfGoodsSold": {
          #   object (Price)
          # },
          # "source": string,
          # "includedDestinations": [
          #   string
          # ],
          # "excludedDestinations": [
          #   string
          # ],
          # "adsGrouping": string, CHECK WITH ALEX
          # "adsLabels": [
          #   string
          # ],
          # "adsRedirect": string,
          # productTypes: [product['category']],
          # "ageGroup": '18-65', CHECK WITH ALEX
          availability: REGULAR_DEFAULT_STOCK,
          condition: 'new',
          # "gender": string,
          sizeSystem: 'US',
          sizeType: 'regular'
          # "additionalSizeType": string,
          # "energyEfficiencyClass": string,
          # "minEnergyEfficiencyClass": string,
          # "maxEnergyEfficiencyClass": string,
          # "taxCategory": string,
          # "transitTimeLabel": string,
          # "shoppingAdsExcludedCountries": [
          #   string
          # ],
          # "productDetails": [ { object (ProductProductDetail) } ],
          # "productHighlights": [ # CHECK WITH ALEX
          #   string
          # ],
          # "subscriptionCost": {
          #   object (ProductSubscriptionCost)
          # },
          # "canonicalLink": string
        }
        if product['sale_price']
          data[:salePrice] = {
            value: product['sale_price'],
            currency: 'USD'
          }
        end
        data
      end

      def get_zipcodes_for_city(city)
        city_sql = ZIPCODES_SQL.gsub('{city_name}', city)
        ActiveRecord::Base.connection.execute(city_sql)
      end
    end

    PRODUCTS_SQL = %{
      SELECT
        DISTINCT ON (products.id) products.id AS id,
        brands.name AS brand,
        CASE
          WHEN  (product_groupings.description IS NOT NULL AND  product_groupings.description != '')
            THEN product_groupings.description
            ELSE variants.name
        END AS description,
        CASE
          WHEN p_images.id IS NULL
            THEN NULL
          WHEN p_images.photo_file_name NOT LIKE '%.%'
            THEN 'https://cdn.minibardelivery.com/products/' || p_images.id || '/product/' || p_images.photo_file_name || '.jpg'
          ELSE 'https://cdn.minibardelivery.com/products/' || p_images.id || '/product/' || regexp_replace(p_images.photo_file_name, '\.png$|\.PNG$|\.JPG$|\.jpe$|\.GIF$|\.gif$', '.jpg')
        END AS product_image_link,
        CASE
          WHEN pg_images.id IS NULL
            THEN NULL
          WHEN pg_images.photo_file_name NOT LIKE '%.%'
            THEN 'https://cdn.minibardelivery.com/products/' || pg_images.id || '/product/' || pg_images.photo_file_name || '.jpg'
          ELSE 'https://cdn.minibardelivery.com/products/' || pg_images.id || '/product/' || regexp_replace(pg_images.photo_file_name, '\.png$|\.PNG$|\.JPG$|\.jpe$|\.GIF$|\.gif$', '.jpg')
        END AS grouping_image_link,
        'https://minibardelivery.com/store/product/' || product_groupings.permalink || '/' || products.permalink || '?via=shipped#{ADD_REGION_ID ? '&region_id=12349876' : ''}' AS link,
        variants.price AS price,
        CASE
          WHEN variants.sale_price = 0 OR variants.sale_price IS NULL
            THEN NULL
          ELSE variants.sale_price
        END as sale_price,
        'out of stock' as availability,
        product_groupings.name AS title,
        products.container_type AS container_type,
        products.volume_value AS volume_value,
        products.volume_unit AS volume_unit,
        product_types.name as subtype,
        category_type.name as category,
        shipping_methods.delivery_fee as shipping_price,
        products.upc as gtin,
        product_groupings.id as group_id,
        inventories.count_on_hand as stock
      FROM products
        JOIN product_groupings ON products.product_grouping_id = product_groupings.id
        JOIN variants ON variants.product_id = products.id AND variants.name IS NOT NULL
        JOIN brands ON product_groupings.brand_id = brands.id
        LEFT JOIN images p_images ON (products.id = p_images.imageable_id AND p_images.imageable_type = 'Product')
        LEFT JOIN images pg_images ON (product_groupings.id = pg_images.imageable_id AND pg_images.imageable_type = 'ProductSizeGrouping')
        JOIN product_types ON product_groupings.hierarchy_type_id = product_types.id
        JOIN product_types as category_type ON category_type.id = product_types.parent_id
        JOIN suppliers ON suppliers.id = variants.supplier_id
        JOIN shipping_methods on shipping_methods.supplier_id = suppliers.id
        JOIN delivery_zones on delivery_zones.shipping_method_id = shipping_methods.id
        JOIN inventories on inventories.id = variants.inventory_id
      WHERE products.deleted_at IS NULL
        AND products.state = 'active'
        AND variants.deleted_at IS NULL
        AND shipping_methods.deleted_at IS NULL
        AND delivery_zones.deleted_at IS NULL
        AND suppliers.active = TRUE
        AND shipping_methods.active = TRUE
        AND shipping_methods.shipping_type = 2 -- shipped
        AND delivery_zones.active = TRUE
        AND delivery_zones.type = 'DeliveryZoneState'
        AND delivery_zones.value = 'NY' -- Available in NYS
        AND variants.supplier_id = suppliers.id
        AND inventories.count_on_hand > 10 -- has stock available
      GROUP BY
        brands.id,
        p_images.id,
        p_images.imageable_id,
        pg_images.id,
        pg_images.imageable_id,
        product_groupings.id,
        category_type.id,
        product_types.id,
        products.id,
        variants.id,
        variants.product_id,
        shipping_methods.id,
        inventories.id
      ORDER BY products.id, variants.price ASC
    }.freeze

    REGIONS_SQL = %{
      SELECT
        DISTINCT ON (products.id) products.id AS id,
        #{REGION_ID} as region_id,
        'in stock' as availability
      FROM products
        JOIN product_groupings ON products.product_grouping_id = product_groupings.id
        JOIN variants ON variants.product_id = products.id AND variants.name IS NOT NULL
        JOIN brands ON product_groupings.brand_id = brands.id
        JOIN images ON product_groupings.id = images.imageable_id AND images.imageable_type = 'ProductSizeGrouping'
        JOIN product_types ON product_groupings.hierarchy_type_id = product_types.id
        JOIN product_types as category_type ON category_type.id = product_types.parent_id
        JOIN suppliers ON suppliers.id = variants.supplier_id
        JOIN shipping_methods on shipping_methods.supplier_id = suppliers.id
        JOIN delivery_zones on delivery_zones.shipping_method_id = shipping_methods.id
        JOIN inventories on inventories.id = variants.inventory_id
      WHERE products.deleted_at IS NULL
        AND products.state = 'active'
        AND variants.deleted_at IS NULL
        AND shipping_methods.deleted_at IS NULL
        AND delivery_zones.deleted_at IS NULL
        AND suppliers.active = TRUE
        AND shipping_methods.active = TRUE
        AND shipping_methods.shipping_type = 2 -- shipped
        AND delivery_zones.active = TRUE
        AND delivery_zones.type = 'DeliveryZoneState'
        AND delivery_zones.value = 'NY' -- Available in NYS
        AND variants.supplier_id = suppliers.id
        AND inventories.count_on_hand > 10 -- has stock available
      GROUP BY
        products.id,
        variants.id
      ORDER BY products.id, variants.price ASC
    }.freeze

    # This is a simple backup, google "top 10 cities in xxx state" and find those cities
    # then use pgadmin to easily copy paste each city, check zipcodes, paste on
    ZIPCODES_SQL = %{
      SELECT zipcode_geoms.zcta5ce20::integer as zipcode
      FROM zipcode_geoms
      INNER JOIN city_geoms
        ON city_geoms.namelsad = '{city_name}'
        AND postgis.ST_Contains(city_geoms.geom, zipcode_geoms.geom)
    }.freeze
  end
end
