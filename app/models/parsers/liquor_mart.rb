module Parsers
  class LiquorMart < CSVParser
    # Headers:
    # Item Number, Normal Description, Vintage, Size Description, Unit Retail, Pack Retail, Units per Pack, Quantity on Hand, Most Recent UPC Code, Department Name, Group Name, Sub-department Name, Case Sale Retail, Region, Sub Region #1, Sub Region #2, Grape, Color, Classification, Full Case Discount, Mixed Case Discount, Full Bar Code (Prefix, Data, Suffix)

    def parse_row(row)
      return if %w[TOBACCO BARWARE MISCELANEOUS].include?(row[:group_name])
      return if price_inconsistent(row)

      @products << {
        sku: row[:item_number].to_s,
        name: DataCleaners::Cleaner::Name.clean(row[:normal_description]),
        volume: volume(row),
        price: DataCleaners::Parser::Price.parse(price(row)),
        quantity: DataCleaners::Parser::Inventory.parse(row[:quantity_on_hand]),
        upc: DataCleaners::Parser::Upc.parse(row[:most_recent_upc_code]) || DataCleaners::Parser::Upc.parse(row[:"full_bar_code_(prefix,_data,_suffix)"]),
        category: category_name(row),
        subtype: row[:grape],
        year: row[:vintage],
        region: region(row),
        original_name: "#{row[:normal_description]} - #{row[:units_per_pack]}pack #{row[:size_description]}"
      }
    end

    private

    def price_inconsistent(row)
      is_one_pack = row[:units_per_pack] == 1

      # in their inventory, for a one pack, the pack retail should either be 0 or eq to the unit retail
      valid_single_pack_price = row[:unit_retail] == row[:pack_retail] || (row[:pack_retail]).zero?

      # the price is invalid if its a one pack but the prices dont line up
      is_one_pack && !valid_single_pack_price
    end

    def price(row)
      row[:units_per_pack] == 1 ? row[:unit_retail] : row[:pack_retail]
    end

    def volume(row)
      volume = DataCleaners::Parser::Volume.parse("#{row[:units_per_pack]}pack #{row[:size_description]}")
      volume[:container_type] ||= 'CAN' if row[:normal_description].to_s =~ /\bcan\b/i
      volume
    end

    def region(row)
      unprefixed = row[:region].to_s.gsub(/[a-zA-Z]\b+-/, '')
      unprefixed.strip.titleize
    end

    def category_name(row)
      category_translator = {
        'BEER': 'beer',
        'LIQUOR': 'liquor',
        'MIX': 'mixers',
        'WINE': 'wine'
      }

      category_translator[row[:group_name]]
    end
  end
end
