module StorefrontFonts
  class Update
    attr_reader :params, :storefront_font

    def initialize(storefront_font, params)
      @storefront_font = storefront_font
      @params = params
    end

    def call
      @success = storefront_font.update(params)

      self
    end

    def success?
      @success
    end
  end
end
