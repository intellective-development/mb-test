module Parsers
  class TotalWine < CSVParser
    SMARTER_CSV_OPTIONS = {
      convert_values_to_numeric: false,
      chunk_size: 250
    }.freeze

    def parse_row(row)
      upc_code = row[:universal_product_code]
      upc_code = row[:warehouse_code] if upc_code == 'NULL'

      @products << {
        sku: (row[:retailer_product_code]).to_s,
        name: DataCleaners::Cleaner::Name.clean(row[:item_name]),
        volume: DataCleaners::Parser::Volume.parse(total_wine_volume(row)),
        price: DataCleaners::Parser::Price.parse(row[:retail_price]),
        category: total_wine_category(row),
        upc: DataCleaners::Parser::Upc.parse(upc_code),
        quantity: DataCleaners::Parser::Inventory.parse(row[:inventory_quantity]),
        alcohol: row[:alcohol_by_volume],
        brand: row[:brand_name],
        gluten_free: String(row[:gluten_free]) == 'TRUE' ? 'Yes' : 'No',
        kosher: String(row[:kosher]) == 'TRUE' ? 'Yes' : 'No',
        description: filter_description(row[:item_details]),
        type: total_wine_type(row),
        varietal: total_wine_varietal(row),
        subtype: total_wine_varietal(row),
        image_url: row[:remote_image_url],
        region: row[:region] != 'NULL' ? row[:region] : nil,
        country: DataCleaners::Cleaner::Country.clean(row[:country_state]),
        appellation: row[:appellation] != 'NULL' ? row[:appellation] : nil,
        original_name: "#{row[:item_name]} #{row[:size]}",
        case_eligible: case_eligible?(row)
      }
    end

    private

    CASE_ELIGIBLE_SIZES = ['1.5L', '750ml', '1L', '3L', '5L'].freeze

    def case_eligible?(row)
      row[:strategy] == 'WD' && CASE_ELIGIBLE_SIZES.include?(row[:size])
    end

    def total_wine_volume(row)
      volume = row[:size]
      volume += String(row[:container_type]) unless String(row[:container_type]) == 'NULL'
      volume
    end

    def total_wine_category(row)
      translator = {
        'spirits': 'liquor',
        'beer': 'beer',
        'wine': 'wine'
      }

      translator[String(row[:department]).downcase]
    end

    def total_wine_varietal(row)
      row[:varietal] if total_wine_category(row) == 'wine'
    end

    def total_wine_type(row)
      case String(row[:product_type]).downcase
      when 'red wine' then 'red'
      when 'white wine' then 'white'
      when 'rose & blush wine' then 'rose'
      else
        row[:product_type]
      end
    end

    def filter_description(text)
      String(text).downcase.include?('total wine') ? nil : String(text).gsub(/^.*-\s/, '')
    end
  end
end
