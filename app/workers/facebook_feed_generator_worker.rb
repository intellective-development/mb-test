class FacebookFeedGeneratorWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  S3_FACEBOOK_VARIANTS_FEED_PATH = 'facebook_variants_feed.csv'.freeze
  S3_FACEBOOK_GEO_FEED_PATH = 'facebook_geo_feed.csv'.freeze

  sidekiq_options \
    queue: 'facebook_feed_generator',
    retry: false,
    uniq: :until_execution

  def perform_with_error_handling
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    s3_bucket = s3.bucket(ENV['AWS_BUCKET'])

    # top-level variant feed
    temp_file = Tempfile.new

    psql_connection = ActiveRecord::Base.connection.raw_connection
    psql_connection.copy_data("COPY (#{facebook_feed_query}) TO STDOUT WITH CSV HEADER") do
      while (row = psql_connection.get_copy_data)
        temp_file << row.force_encoding('utf-8')
      end
    end

    temp_file.flush

    s3_bucket.object(S3_FACEBOOK_VARIANTS_FEED_PATH).upload_file(temp_file, acl: 'public-read')

    update_delivery_zone_info

    # geo, supplier-specific variant feed
    temp_file = Tempfile.new

    psql_connection = ActiveRecord::Base.connection.raw_connection
    psql_connection.copy_data("COPY (#{facebook_geo_query}) TO STDOUT WITH CSV HEADER") do
      while (row = psql_connection.get_copy_data)
        temp_file << row.force_encoding('utf-8')
      end
    end

    temp_file.flush

    s3_bucket.object(S3_FACEBOOK_GEO_FEED_PATH).upload_file(temp_file, acl: 'public-read')
  end

  private

  def facebook_feed_query
    %(
      SELECT
        DISTINCT ON (products.id) products.id AS id,
        CASE
          WHEN (inventories.count_on_hand - inventories.count_pending_to_customer) > 2
            THEN 'in stock'
            ELSE 'out of stock'
        END AS availability,
        brands.name AS brand,
        'new' AS condition,
        CASE
          WHEN  (product_groupings.description IS NOT NULL AND  product_groupings.description != '')
            THEN product_groupings.description
            ELSE variants.name
        END AS description,
        CASE
          WHEN images.photo_file_name NOT LIKE '%.%'
            THEN 'https://cdn.minibardelivery.com/products/' || images.id || '/product/' || images.photo_file_name || '.jpg'
            ELSE 'https://cdn.minibardelivery.com/products/' || images.id || '/product/' || regexp_replace(images.photo_file_name, '\.png$|\.PNG$|\.JPG$|\.jpe$|\.GIF$|\.gif$', '.jpg')
        END AS image_link,
        'https://minibardelivery.com/store/product/' || product_groupings.permalink AS link,
        CONCAT('/store/product/', product_groupings.permalink) AS custom_label_0,
        product_groupings.id as item_group_id,
        variants.price AS price,
        product_groupings.name AS title,
        CONCAT('minibar://minibardelivery.com/store/product/', product_groupings.permalink) AS ios_url,
        CONCAT('minibar://minibardelivery.com/store/product/', product_groupings.permalink) AS android_url,
        'minibar.android' AS android_package,
        'Minibar Delivery' AS android_app_name,
        'Minibar Delivery' AS ios_app_name,
        '720850888' AS ios_app_store_id
      FROM products
        JOIN product_groupings ON products.product_grouping_id = product_groupings.id
        JOIN variants ON variants.product_id = products.id AND variants.name IS NOT NULL
        JOIN brands ON product_groupings.brand_id = brands.id
        JOIN images ON product_groupings.id = images.imageable_id AND images.imageable_type = 'ProductSizeGrouping'
        JOIN inventories ON variants.inventory_id = inventories.id
      WHERE products.deleted_at IS NULL
        AND products.state = 'active'
        AND variants.deleted_at IS NULL
      GROUP BY
        brands.id,
        images.id,
        images.imageable_id,
        inventories.id,
        product_groupings.id,
        products.id,
        variants.id,
        variants.product_id
    )
  end

  def facebook_geo_query
    %(
      SELECT
        products.id AS id,
        suppliers.id AS override,
        CONCAT(variants.price, ' USD') AS price,
        supplier_facebook_caches.delivery_zone_cache as availability_polygon_coordinates,
        suppliers.name AS supplier_name,
        CASE
          WHEN (inventories.count_on_hand - inventories.count_pending_to_customer) > 2
            THEN 'in stock'
            ELSE 'out of stock'
        END AS availability
      FROM products
        JOIN variants ON variants.product_id = products.id AND variants.name IS NOT NULL
        JOIN inventories ON variants.inventory_id = inventories.id
        JOIN suppliers ON variants.supplier_id = suppliers.id
        JOIN supplier_facebook_caches ON suppliers.id = supplier_facebook_caches.supplier_id
      WHERE products.deleted_at IS NULL
        AND products.state = 'active'
        AND variants.deleted_at IS NULL
        AND suppliers.active = TRUE
      GROUP BY
        products.id,
        suppliers.id,
        supplier_facebook_caches.id,
        inventories.id,
        variants.id,
        variants.product_id
    )
  end

  def update_delivery_zone_info
    Supplier.find_each do |supplier|
      # remove cache records for this supplier
      supplier.supplier_facebook_caches.destroy_all

      zone_added = false

      supplier.shipping_methods.active.each do |shipping_method|
        shipping_method.delivery_zones.active.polygons.find_each do |zone|
          unless zone.json['coordinates'].nil? || zone_added
            zone_added = true

            zone_data = '['
            zone_items = []

            zone.json['coordinates'].first.each do |coord|
              zone_items.append "{'latitude': #{coord[1]}, 'longitude': #{coord[0]}}"
            end

            zone_data += zone_items.join ','
            zone_data += ']'

            supplier.supplier_facebook_caches.create(delivery_zone_cache: zone_data, delivery_zone_id: zone.id)
          end
        end
      end
    end
  end
end
