module Content
  class LinkList
    attr_reader :config, :options

    # Options
    # =======
    # - `content` - Array<{ internal_name: string, name: string, action_url: string }>
    def initialize(options)
      @options = options
      generate_config
    end

    def generate_config
      @config = {
        content: options[:content].presence,
        title: options[:title].presence
      }
    end
  end
end
