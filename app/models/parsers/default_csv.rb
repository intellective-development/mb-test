# frozen_string_literal: true

module Parsers
  class DefaultCSV < CSVParser
    SMARTER_CSV_OPTIONS = {
      headers: true,
      remove_empty_values: false
    }.freeze

    FILE_ENCODING = 'r:iso-8859-1'

    def parse_row(row)
      sku = row[:sku]

      if volume_parts_present?(row)
        vol = {
          container_count: row[:container_count],
          container_type: row[:container_type].to_s.upcase,
          volume_unit: row[:volume_unit].to_s.upcase,
          volume_value: row[:volume_value]
        }
        identifier = "#{row[:name]}#{vol.inspect}"
      else
        vol = DataCleaners::Parser::Volume.parse(row[:volume])
        identifier = "#{row[:name]}#{vol[:item_volume]}"
      end
      sku ||= DataCleaners::Parser::Sku.generate_sku(identifier)

      @products << {
        sku: sku.to_s,
        name: DataCleaners::Cleaner::Name.clean(row[:name]),
        description: row[:description],
        brand: DataCleaners::Cleaner::Name.clean(row[:brand].to_s),
        quantity: DataCleaners::Parser::Inventory.parse(row[:inventory]),
        volume: vol,
        price: DataCleaners::Parser::Price.parse(row[:price]),
        sale_price: DataCleaners::Parser::Price.parse(row[:sale_price]),
        category: row[:category],
        type: row[:type],
        varietal: row[:varietal],
        subtype: row[:subtype],
        alcohol: row[:alcohol],
        region: row[:region],
        country: row[:country],
        appellation: row[:appellation],
        year: row[:year],
        organic: parse_binary(row[:organic]),
        screwcap: parse_binary(row[:screwcap]),
        kosher: parse_binary(row[:kosher]),
        upc: DataCleaners::Parser::Upc.parse(row[:upc1]) || DataCleaners::Parser::Upc.parse(row[:upc]),
        original_name: identifier
      }
    end

    private

    def volume_parts_present?(row)
      row.key?(:container_count) && row.key?(:container_type) && row.key?(:volume_value) && row.key?(:volume_unit)
    end

    def parse_binary(binary)
      binary.present? ? 'Yes' : nil
    end
  end
end
