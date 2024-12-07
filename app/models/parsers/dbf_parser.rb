module Parsers
  class DBFParser < BaseParser
    require 'dbf'

    include SentryNotifiable

    attr_accessor :db

    def initialize(url)
      raise 'File URL required' if url.nil?

      uri = URI.parse(url)
      @db = DBF::Table.new(uri.open)

      parse
    end

    def parse
      @db.each do |row|
        parse_row(row) unless row.nil?
      rescue StandardError => e
        notify_sentry_and_log(e)
      end
    end

    def parse_row(_row)
      raise 'Not Implemented'
    end
  end
end
