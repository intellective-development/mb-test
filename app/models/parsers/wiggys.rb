module Parsers
  class Wiggys < BaseParser
    require 'roo'

    SKIP_DEPARTMENTS = ['CIGARS', '50 ML & 100 ML', 'IMPORTED CIGARETTES', 'KEG', 'KEGS', 'SYSTEM',
                        'WINE ACC, GLASSWARE, GIFTS ETC', '200ML', '50 ML', 'CHARGEBACK',
                        'DOMESTIC CIGARETTES'].freeze

    def initialize(url)
      uri = URI.parse(url)
      @feed = uri.open('r:ISO-8859-1')

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

      total_rows = xls.last_row
      current_row = 7
      while current_row < total_rows
        item_name  = DataCleaners::Cleaner::Name.clean(xls.row(current_row)[0])
        department = xls.row(current_row)[2].to_s.upcase
        upc        = xls.row(current_row)[6]
        sku        = xls.row(current_row)[8].to_i.to_s
        price      = DataCleaners::Parser::Price.parse(xls.row(current_row)[10])
        quantity   = DataCleaners::Parser::Inventory.parse(xls.row(current_row)[12])

        unless SKIP_DEPARTMENTS.include?(department) || upc.blank? || department == 'CS'
          @products << {
            sku: sku,
            original_name: xls.row(current_row)[0],
            name: item_name,
            quantity: quantity,
            price: price,
            volume: DataCleaners::Parser::Volume.parse(item_name),
            upc: DataCleaners::Parser::Upc.parse(upc),
            category: wiggy_category(department)
          }
        end

        current_row += 1
      end
    end

    private

    def wiggy_category(department)
      department = department.to_s.upcase
      if department.include?('WINE') || department.include?('SAKE') || department.include?('SHERRYS')
        'wine'
      elsif department.include?('BEER')
        'beer'
      elsif department.include?('MIXERS') || department.include?('SNACKS')
        'mixers'
      else
        'liquor'
      end
    end
  end
end
