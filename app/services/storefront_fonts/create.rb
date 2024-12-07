module StorefrontFonts
  class Create
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def call
      @success = storefront_font.save

      self
    end

    def storefront_font
      @storefront_font ||= StorefrontFont.new(params)
    end

    def success?
      @success
    end
  end
end
