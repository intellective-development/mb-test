class BuildKnownProductsIndexService
  require 'elasticsearch'
  require 'data_cleaners'

  INDEX_DEFINITION = {
    mappings: {
      properties: {
        upc: {
          type: 'keyword'
        },
        alt_upcs: {
          type: 'keyword'
        },
        name: {
          type: 'text'
        },
        alt_names: {
          type: 'text'
        },
        volume_string: {
          type: 'keyword'
        },
        price: {
          type: 'float'
        },
        volume_ml: {
          type: 'float'
        },
        container_count: {
          type: 'long'
        },
        container_type: {
          type: 'keyword'
        },
        age: {
          type: 'float'
        },
        permalink: {
          type: 'keyword'
        }
      }
    }
  }.freeze

  def initialize
    @client = Elasticsearch::Client.new(url: ENV['ELASTICSEARCH_URL'])
    @name_cleaner = DataCleaners::Name.new
  end

  def update_product(id)
    product = Product.find id
    if product.state == 'active'
      product = build_query(id)
      if product.empty?
        delete_product(id)
      else
        @client.index(
          index: 'known_products',
          id: product[0][:id],
          body: build_product(product[0])
        )
      end
    else
      delete_product(id)
    end
  end

  BATCH_SIZE = 500
  def call(start = nil)
    unless start
      @client.indices.delete(index: 'known_products') if @client.indices.exists?(index: 'known_products')
      @client.indices.create(index: 'known_products', body: INDEX_DEFINITION)
    end

    build_query.find_in_batches(batch_size: BATCH_SIZE, start: start) do |records|
      start = (start || 0) + BATCH_SIZE
      Rails.logger.error("Batch at #{start}")
      @client.bulk(
        index: 'known_products',
        body: records.map { |record| { index: { data: build_product(record), _id: record[:id] } } }
      )
    end
  end

  private

  def delete_product(id)
    @client.delete(
      index: 'known_products',
      id: id
    )
  rescue StandardError => e
    Rails.logger.error "Error deleting known product '#{id}': #{e}" unless e.instance_of?(Elasticsearch::Transport::Transport::Errors::NotFound)
  end

  def build_query(id = nil)
    query = { state: 'active', product_groupings: { state: 'active' }, variants: { deleted_at: nil } }
    query[:id] = id if id
    Product.joins(:variants).joins(product_size_grouping: [:brand]).where(query).select("
      products.id as id,
      brands.name as brand,
      product_groupings.name as name,
      products.item_volume as volume,
      products.container_type as container_type,
      products.upc as upc,
      products.additional_upcs as additional_upcs,
      json_agg(DISTINCT products.permalink) as permalinks,
      json_agg(variants.original_name) as original_names,
      json_agg(variants.price) as prices
      ").group('products.id', 'brands.name', 'product_groupings.name', 'products.item_volume', 'products.container_type', 'upc', 'additional_upcs')
  end

  def build_product(record)
    upcs = []
    upcs << record[:upc] if record[:upc]
    upcs += record[:additional_upcs]
    upcs = upcs.map { |upc| DataCleaners::Upc.format(upc, nil) }.compact
    permalink = record[:permalinks].min_by(&:size) # assume shortest-sized permalinks are more accurate

    name = [record[:brand], record[:name]].compact.join(' ')
    p = @name_cleaner.format(name)

    original_products = record[:original_names].map { |original_name| @name_cleaner.format(original_name) }
    alt_names   = original_products.map { |product| product[:name] }.select(&:present?)
    alt_volumes = original_products.map { |product| DataCleaners::Volume.format(product) }.select { |volume| volume[:volume_ml] }
    alt_ages = ([p[:age]] + original_products.map { |product| product[:age] }).compact.uniq

    v = DataCleaners::Volume.format(
      (median(alt_volumes, :volume_ml) || {})
      .merge(@name_cleaner.format(record[:volume]))
      .merge(@name_cleaner.format(record[:container_type]))
    )

    price = median(record[:prices])

    {
      'upc' => upcs[0],
      'name' => p[:name],
      'volume_string' => v[:volume_string],
      'container_count' => v[:container_count],
      'container_type' => v[:container_type],
      'volume_ml' => v[:volume_ml],
      'price' => price,
      'age' => alt_ages,

      'alt_upcs' => upcs,
      'alt_names' => alt_names,
      'permalink' => permalink
    }
  end

  def median(array, key = nil)
    len = array.length
    if key
      array.sort_by { |h| h[key] }[len / 2]
    else
      sorted = array.sort
      (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
    end
  end
end
