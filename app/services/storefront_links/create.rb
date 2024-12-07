module StorefrontLinks
  class Create
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def call
      @success = storefront_link.save

      self
    end

    def storefront_link
      @storefront_link ||= StorefrontLink.new(params)
    end

    def success?
      @success
    end
  end
end
