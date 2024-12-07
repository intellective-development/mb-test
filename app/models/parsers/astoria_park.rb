module Parsers
  class AstoriaPark < CSVParser
    include DataCleaner

    # Notes for ICS Vision-type POS system
    # =====
    # => Price is dependant on units_per_pack
    #      - If >  1 then use item_pack_price
    #      - If == 1 then use item_unit_price
    # => Vintage field is useful, should be noted it doesn't appear in name
    # => Region should be [subregion, region].compact.join(', ')
    # => Varietal should be used.
    # => Color very useful for wine.
    HEADER_MAPPINGS = %i[item_number item_description item_vintage item_notes item_size_description item_long_description units_per_case item_unit_price item_pack_price units_per_pack warm_case_price quantity_on_hand upc dept_name dept_group_name subdept_name vendor alcohol_proof tax_flag item_unit_sale_price item_case_sale_price sale_start_date sale_end_date tasting_notes country_of_origin region sub_region_1 sub_region_2 varietal color classification winemaker winery special_rating parker_rating other_rating featured url cost_per_bottle sale_code pack_sale_price full_case_discount mixed_case_discount max_units_to_sell misc_web web_unit_price web_pack_price web_case_price web_unit_sale_price web_pack_sale_price web_case_sale_price web_sale_type web_sale_start_date web_sale_end_date units_on_open_pos item_points web_id quantity_available_to_sell continent vineyard item_flags on_cust_order recent_upc date_item_inserted image_url item_location wine_condition item_weight tax_percentage].freeze

    SMARTER_CSV_OPTIONS = {
      col_sep: "\t",
      quote_char: '',
      convert_values_to_numeric: false,
      force_simple_split: true,
      user_provided_headers: HEADER_MAPPINGS.dup
    }.freeze

    def parse_row(row)
      @products << {
        sku: (row[:item_number]).to_s,
        name: DataCleaners::Cleaner::Name.clean(row[:item_description]),
        quantity: DataCleaners::Parser::Inventory.parse(row[:quantity_on_hand]),
        volume: DataCleaners::Parser::Volume.parse(row[:item_size_description]),
        price: DataCleaners::Parser::Price.parse(find_price(row)),
        category: mtw_category(row),
        type: mtw_type(row),
        region: mtw_region(row),
        varietal: row[:varietal].to_s.titleize,
        country: DataCleaners::Cleaner::Country.clean(row[:country_of_origin]),
        year: DataCleaners::Parser::Year.parse(row[:item_vintage]),
        upc: DataCleaners::Parser::Upc.parse(row[:upc]),
        original_name: "#{row[:item_description]} #{row[:item_size_description]}"
      }
    end

    private

    def mtw_category(row)
      return 'wine'   if row[:dept_group_name].to_s.include?('WINE')
      return 'liquor' if row[:dept_group_name].to_s.include?('LIQUOR')
    end

    def mtw_type(row)
      return row[:color] if row[:color].present?

      row[:subdept_name]
    end

    def mtw_region(row)
      [row[:sub_region_1], row[:region]].compact.uniq.join(', ').to_s.titleize
    end

    def find_price(row)
      if row[:units_per_pack].to_i == 1
        row[:item_unit_price]
      else
        row[:item_pack_price]
      end
    end
  end
end
