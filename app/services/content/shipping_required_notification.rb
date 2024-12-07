module Content
  class ShippingRequiredNotification
    attr_reader :config

    def initialize(_options)
      generate_config
    end

    def generate_config
      @config = {}
    end
  end
end
