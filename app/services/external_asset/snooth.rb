# frozen_string_literal: true

class ExternalAsset
  class Snooth < BaseAsset
    SNOOTH_API_KEY = 'umcyysrvymq4ds5ojm4aw4inr80l9u9wyhx9hvr70x8xssdp'

    def api_url
      'http://api.snooth.com/'
    end

    def search_by_product(product)
      response = conn.get 'wines', akey: SNOOTH_API_KEY, q: product.name, a: 0, t: 'wine'
      JSON.parse(response.body)['wines']
    end

    def find_similar(product, result)
      similarity = result['name'].similar(product.name)
      if similarity > @best_similarity && similarity > similarity_threshold
        @best_similarity = similarity
        @api_product = result
      end
    end

    def update_custom_fields(product)
      product.update_property('appellation', product_appellation)
      product.update_property('snooth_id', product_id)
      product.update_property('snooth_rating', snooth_rating)
      product.update_property('snooth_similarity', product_similarity)
      product.update_property('varietal', product_varietal)
      product
    end

    # ###PROPERTY ACCESSORS, given the product block for a single product
    def product_varietal
      @api_product['varietal']
    end

    def product_brand
      Brand.find_or_create_by(name: @api_product['winery'])
    end

    def product_name
      @api_product['name']
    end

    def product_country
      @api_product['region'].split(' > ')[1]
    end

    def product_region
      @api_product['region'].split(' > ')[1]
    end

    def product_appellation
      @api_product['region'].split(' > ')[2]
    end

    def snooth_rating
      @api_product['snoothrank']
    end

    def product_id
      @api_product['code']
    end
  end
end
