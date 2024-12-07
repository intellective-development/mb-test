module Content
  class BrandDescription
    attr_reader :config, :options

    # Options
    # =======
    # - `brand_id`, DEPRECATED - the brand that will be passed back in config
    # - `brand`, the brand that will be passed back in config
    def initialize(options)
      @options = options
      @brand = brand

      generate_config
    end

    def generate_config
      brand_options = { platform: options[:platform] }

      @config = {
        brand: ConsumerAPIV2::Entities::Brand.represent(brand, brand_options)
      }
    end

    private

    def brand
      @brand ||= Brand.find_by(permalink: options[:brand] || options[:brand_id])
    end
  end
end
