class ExternalAsset
  class Distiller < BaseAsset
    def api_url
      'https://drinkdistiller.com/api/v1/spirits/'
    end

    attr_reader :ngrams

    def search_by_name(name)
      response = conn.get 'search.json', q: name
      JSON.parse(response.body)
    end

    def gen_ngrams(product)
      words = product.name.split
      if words.length == 1
        @ngrams = words
      else
        @ngrams = (2..3).to_a.map { |n| product.name.split.each_cons(n).to_a.map { |x| x.join(' ') } }.flatten
        @ngrams.sort_by!(&:length)
      end
    end

    def search_by_product(product)
      gen_ngrams(product)
      search_results = @ngrams.map { |ngram| search_by_name(ngram) }.flatten.uniq
      search_results.map { |result| get_by_id(result['id']) }
    end

    def get_by_id(id)
      id = id.to_s
      response = conn.get "#{id}.json"
      JSON.parse(response.body)
    end

    def get_related_by_id(id)
      response = conn.get "#{id}/related.json"
      JSON.parse(response.body)
    end

    def find_similar(_product, result)
      # @ngrams is sorted by length of string
      # the rules: high similarity scores conquer all; if score is tied, longer string wins
      @ngrams.each do |ngram|
        similarity = result['name'].similar(ngram)
        if similarity >= @best_similarity && similarity > similarity_threshold
          @best_similarity = similarity
          @api_product = result
        end
      end
    end

    def update_custom_fields(product)
      # additional distiller fields
      product.update_property('distiller_id', product_id)
      product.update_property('distiller_expert_rating', distiller_expert_rating)
      product.update_property('distiller_similarity', product_similarity)
      product
    end

    def product_name
      @api_product['name']
    end

    def product_region
      @api_product['location']
    end

    def product_country
      @api_product['country']
    end

    def product_alcohol
      @api_product['proof'].to_f / 2.0
    end

    def product_brand
      Brand.find_or_create_by(name: @api_product['brand'])
    end

    def product_id
      @api_product['id']
    end

    def distiller_expert_rating
      @api_product['expert_rating']
    end
  end
end
