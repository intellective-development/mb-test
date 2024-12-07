module Parsers
  class ThirstyQuaker < BaseParser
    HEADER_MAPPING = {
      itemnum: 'ItemNum',
      itemname: 'ItemName',
      itemname_extra: 'ItemName_Extra',
      price: 'Price',
      in_stock: 'In_Stock',
      dept_id: 'Dept_ID'
    }.freeze

    EXCLUDED_DEPTS = %w[Kit Yeast Hops Grain Extract Honey Addins MakeWine Others Equip Coupons Media Chems Labels Bottles NONE].freeze

    require 'roo'

    def initialize(url)
      uri = URI.parse(url)
      @feed = uri.open('r:ISO-8859-1')
      @products = []

      parse if @feed
    end

    def parse
      text = File.read(@feed.path)
      md5 = Digest::MD5.hexdigest(text)

      file = File.open("#{Rails.root}/tmp/#{md5}", 'w')
      file.puts(text)
      file.close

      xls = Roo::Spreadsheet.open(file, extension: :xlsx)
      xls.default_sheet = xls.sheets.first
      xls.parse(HEADER_MAPPING).each do |row|
        # Ignore Brewing Equipment
        next if EXCLUDED_DEPTS.include?(row[:dept_id])

        # Delete any existing elements in the array that contain the same SKU. This is due
        # to a bug on the supplier end where updates to a price/quantity cause a new row
        # to be appended to the database. Assumption is last record is correct.
        @products.delete_if { |el| el[:sku] == row[:itemnum].to_s }
        @products << {
          sku: row[:itemnum].to_s,
          upc: DataCleaners::Parser::Upc.parse(row[:itemnum]),
          name: DataCleaners::Cleaner::Name.clean("#{row[:itemname]} #{row[:itemname_extra]}"),
          price: DataCleaners::Parser::Price.parse(row[:price]),
          quantity: DataCleaners::Parser::Inventory.parse(row[:in_stock]),
          volume: DataCleaners::Parser::Volume.parse(row[:itemname]),
          original_name: row[:itemname]
        }
      end
    end
  end
end
