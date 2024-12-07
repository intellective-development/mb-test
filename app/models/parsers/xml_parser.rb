module Parsers
  class XMLParser < BaseParser
    require 'nokogiri'

    attr_accessor :doc

    def initialize(url)
      raise 'Feed URL required' if url.nil?

      uri = URI.parse(url)
      @doc = Nokogiri::HTML(uri.open)

      parse
    end

    def parse
      @doc.xpath('//rss/channel/item').each do |item|
        parse_row(item)
      end
    end

    def parse_row(item)
      @products << {
        sku: item.xpath('sku').text,
        name: DataCleaners::Cleaner::Name.clean(item.xpath('title').text),
        price: DataCleaners::Parser::Price.parse(item.xpath('price').text),
        volume: DataCleaners::Parser::Volume.parse(item.xpath('format').text),
        quantity: DataCleaners::Parser::Inventory.parse(item.xpath('qty').text),
        original_name: "#{item.xpath('title').text} #{item.xpath('format').text}"
      }
    end
  end
end
