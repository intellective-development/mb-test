class ExternalAsset
  class Anybeer < BaseAsset
    # overwriting conn
    def conn
      db.establish_connection(ENV['DATABASE_URL'])
      db.connection
    end

    def query
      "SELECT
          abv,
          beer_id,
          beer_name,
          brewery_name
        FROM anybeer
      "
    end

    def search_by_product(product)
      # fuzzy search
      conn.execute(query + " WHERE beer_name ~ #{db.sanitize(product.name)};").map { |x| x }
    end

    def find_similar(product, result)
      similarity = result['beer_name'].similar(product.name)
      if similarity > @best_similarity && similarity > similarity_threshold
        @best_similarity = similarity
        @api_product = result
      end
    end

    def cleanup_hash
      @api_product.keys.map { |k| k.to_i == k ? @api_product.delete(k) : nil }
    end

    def update_custom_fields(product)
      product
    end

    def product_name
      @api_product['beer_name']
    end

    def product_alcohol
      @api_product['abv']
    end

    def product_brand
      Brand.find_or_create_by(name: @api_product['brewery_name'])
    end

    def product_id
      @api_product['beer_id']
    end
  end
end
