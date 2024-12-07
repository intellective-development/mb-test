module StorefrontFonts
  class Delete
    attr_reader :storefront_font

    def initialize(storefront_font)
      @storefront_font = storefront_font
    end

    def call
      storefront_font.destroy
      self
    end

    def success?
      storefront_font.destroyed?
    end
  end
end
