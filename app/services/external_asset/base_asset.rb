class ExternalAsset
  class BaseAsset
    require 'aws-sdk'
    require 'similar_text'

    def initialize
      @api_product = {}
      @best_similarity = -1
    end

    attr_reader :api_product, :best_similarity

    def db
      # sometimes needed for rails-y things.
      ActiveRecord::Base
    end

    def found_something?
      !@api_product.empty?
    end

    # please overwrite if you are not using some curl access (like brewdega)
    # always define api_url in the subclass
    def conn
      Faraday.new(url: api_url) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger
        faraday.adapter Faraday.default_adapter
      end
    end

    def api_url
      'http://someones.api.com'
    end

    def s3
      Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    end

    def bucket
      s3.bucket(ENV['AWS_BUCKET'])
    end

    def api_name
      self.class.name.demodulize.downcase
    end

    def similarity_threshold
      # based on pulls from distiller already; we should be tight about it.
      93
    end

    # TODO: Centralize S3 code
    def push
      file_name = "#{api_name}-#{product_id}.json"
      local_file_path = "./tmp/#{file_name}"

      File.open(local_file_path, 'w') do |file|
        file.write(@api_product.to_json)
      end

      object = bucket.object("api_data/#{api_name}/#{file_name}")
      object.upload_file(Pathname.new(local_file_path))
      File.delete(local_file_path)
    end

    def fetch(product, push_to_s3 = false)
      results = search_by_product(product)
      if results.present?
        find_most_similar(product, results)
        push if !@api_product.empty? && push_to_s3
      end
    end

    def fetch_cache_by_id(id)
      file_name = "#{api_name}-#{id}.json"
      object = bucket.object(file_name)
      @api_product = JSON.parse(object.read) if object
    end

    def find_most_similar(product, results)
      results.each do |result|
        find_similar(product, result)
      end
    end

    def update_product(product)
      # base update_product assumes common instance methods
      # any additional fields should be thrown in update_custom_fields()
      # don't change our product names in case the matches are wrong!
      if product.product_size_grouping
        product.product_size_grouping.set_property('region', product_region)   if product_region
        product.product_size_grouping.set_property('country', product_country) if product_country
        product.product_size_grouping.set_property('alcohol', product_alcohol) if product_alcohol
        product.product_size_grouping.brand = product_brand if product_brand && product&.product_size_grouping&.brand&.name == 'Unknown Brand'
      end

      product = update_custom_fields(product)
      # save once to clean up data
      product.save!
      # save another time to update the apis_accessed attribute
      product.update_apis_accessed(api_name)
      product
    end

    def update_custom_fields(product)
      # custom product should always return the product
      product
    end

    def unnest(set, list)
      # function for handling nested json in case expected keys are missing
      list.each do |l|
        return nil if set.nil?

        if set.key? l
          set = set[l]
          return set if l == list.last
        else
          return nil
        end
      end
    end

    def update_api_property(name, value)
      # lazy function for easier testing
      @api_product.update(name => value)
    end

    # all following are defaults and should be updated in subclasses dependent on the hash expected
    def product_name
      @api_product['name']
    end

    def product_region
      @api_product['region']
    end

    def product_country
      @api_product['country']
    end

    def product_alcohol
      @api_product['alcohol']
    end

    def product_brand
      @api_product['brand']
    end

    def product_similarity
      @best_similarity
    end
  end
end
