module StorefrontLinks
  class Update
    attr_reader :params, :storefront_link

    def initialize(storefront_link, params)
      @storefront_link = storefront_link
      @params = params
    end

    def call
      @success = storefront_link.update(params)

      self
    end

    def success?
      @success
    end
  end
end
