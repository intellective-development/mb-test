module Content
  class AppDownload
    attr_reader :config, :options

    def initialize(options)
      @options = options
      generate_config
    end

    def generate_config
      @config = {}.merge(options)
    end
  end
end
