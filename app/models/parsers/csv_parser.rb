# frozen_string_literal: true

module Parsers
  class CSVParser < BaseParser
    require 'smarter_csv'

    SMARTER_CSV_OPTIONS = {
      chunk_size: 500,
      row_sep: :auto,
      skip_blanks: true,
      strip_whitespace: true,
      verbose: true
    }.freeze

    FILE_ENCODING = 'r:UTF-8'

    def initialize(url)
      raise 'Feed URL required' if url.nil?

      uri = URI.parse(url)
      @feed = uri.open(file_encoding)

      options = SMARTER_CSV_OPTIONS.merge(self.class::SMARTER_CSV_OPTIONS)
      @csv = SmarterCSV.process(@feed, options)

      parse
    end

    def parse
      @csv.each do |chunk|
        chunk.each do |row|
          parse_row(row)
        end
      end
    end

    def parse_row(_row)
      raise 'Not Implemented'
    end

    private

    def file_encoding
      self.class::FILE_ENCODING.nil? ? 'r:UTF-8' : self.class::FILE_ENCODING
    end
  end
end
