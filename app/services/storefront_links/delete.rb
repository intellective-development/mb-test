module StorefrontLinks
  class Delete
    attr_reader :storefront_link

    def initialize(storefront_link)
      @storefront_link = storefront_link
    end

    def call
      storefront_link.destroy
      self
    end

    def success?
      storefront_link.destroyed?
    end
  end
end
