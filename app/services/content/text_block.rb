module Content
  class TextBlock
    attr_reader :config, :options

    # Options
    # =======
    # - `title` - The optional title of the module
    # - `sub_title` - The optional sub_title of the module
    # - `body` - The optional body text of the module
    def initialize(options)
      @options = options
      generate_config
    end

    def generate_config
      @config = {
        title: options[:title].presence,
        sub_title: options[:sub_title].presence,
        body: options[:body].presence
      }
    end
  end
end
