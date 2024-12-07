class ExternalAsset
  class Brewdega < BaseAsset
    # overwriting conn
    def conn
      db.establish_connection(ENV['DATABASE_URL'])
      db.connection
    end

    def query
      'SELECT
        beer.id "id",
        beer.name "beer_name",
        abv,
        ibu,
        srm,
        upc,
        beer.descript "beer_description",
        brewery.name "brewery_name",
        address1,
        address2,
        city,
        state,
        code,
        country,
        phone,
        website,
        brewery.descript "brewery_description",
        cat_name,
        style_name
      FROM brewdega_beers beer
      INNER JOIN brewdega_breweries brewery ON brewery.id = beer.brewery_id
      INNER JOIN brewdega_categories cat ON cat.id = beer.cat_id
      INNER JOIN brewdega_styles style ON style.id = beer.style_id'
    end

    def search_by_product(product)
      conn.execute(query + " where beer.name ~ #{db.sanitize(product.name)}").map { |x| x }
    end

    def find_similar(product, result)
      similarity = result['beer_name'].similar(product.name)
      if similarity > @best_similarity && similarity > similarity_threshold
        @best_similarity = similarity
        @api_product = result
      end
    end

    def update_custom_fields(product)
      product.update_property('brewdega_id', product_id)
      product.update_property('brewdega_similarity', product_similarity)
      product
    end

    def product_name
      @api_product['beer_name']
    end

    def product_region
      [@api_product['city'], @api_product['state']].join(' ')
    end

    def product_country
      @api_product['country']
    end

    def product_alcohol
      @api_product['abv']
    end

    def product_brand
      Brand.find_or_create_by(name: @api_product['brand_name'])
    end

    def product_id
      @api_product['id']
    end
  end
end
