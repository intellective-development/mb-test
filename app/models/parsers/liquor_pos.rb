module Parsers
  class LiquorPOS < DBFParser
    def parse_row(row)
      @products << {
        sku: row['CODE_NUM'],
        name: DataCleaners::Cleaner::Name.clean("#{row['BRAND']} #{row['DESCRIP']}"),
        volume: DataCleaners::Parser::Volume.parse((row['SIZE']).to_s),
        original_name: "#{row['BRAND']} #{row['DESCRIP']} #{row['SIZE']}",
        price: DataCleaners::Parser::Price.parse(row['PRICE']),
        quantity: DataCleaners::Parser::Inventory.parse(row['QTY_ON_HND'])
      }
    end
  end
end
