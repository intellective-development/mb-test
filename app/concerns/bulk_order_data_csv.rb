module BulkOrderDataCsv
  require 'csv'

  extend ActiveSupport::Concern

  def parse_raw_csv(raw_csv_data)
    CSV.parse(raw_csv_data, headers: true, skip_blanks: true)
  end
end
