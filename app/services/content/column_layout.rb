module Content
  class ColumnLayout
    attr_reader :config, :options, :content_placement

    def initialize(options)
      @options = options
      generate_config
    end

    def generate_config
      @config = {
        column_section_ids: options[:column_section_ids]
      }
    end
  end
end
