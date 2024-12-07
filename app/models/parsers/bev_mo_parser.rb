module Parsers
  class BevMoParser < BaseParser
    FILE_ENCODING = 'r:UTF-8'.freeze

    def initialize(options)
      raise 'Feed URL required' if options[:url].nil?

      product_feed = URI.parse(options[:url]).open(file_encoding)
      prices_feed = URI.parse(options[:prices_url]).open(file_encoding)

      products = fast_parse_psv(product_feed, :sku)
      prices = fast_parse_psv(prices_feed, nil, :location, [options[:store_number]])
      prices.each do |row|
        parse_row(products, row)
      end
    end

    def fast_parse_psv(psv, hash_key = nil, key = nil, values = nil)
      counter = 0
      headers = {}
      lines = hash_key.nil? ? [] : {}
      IO.foreach(psv) do |line|
        line = line.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        line = line.gsub(/[\r\n]/m, '')
        split = line.split('|')
        headers = split.map(&:to_sym) if counter.zero?
        out = []
        out = headers.zip(split).to_h unless counter.zero?
        lines << out if !out.empty? && (key.nil? || values.include?(out[key])) && hash_key.nil?
        lines[out[hash_key]] = out if !out.empty? && (key.nil? || values.include?(out[key])) && !hash_key.nil?
        counter += 1
      end
      lines
    end

    private

    def file_encoding
      self.class::FILE_ENCODING.nil? ? 'r:UTF-8' : self.class::FILE_ENCODING
    end

    def parse_row(products, price_row)
      product = products[price_row[:sku]]
      unless product.nil?
        parsed_volume = volume(product)
        unless parsed_volume[:container_type].nil? || parsed_volume[:container_type].casecmp?('keg')
          @products << {
            sku: (price_row[:sku]).to_s,
            name: DataCleaners::Cleaner::Name.clean(product[:name]).gsub(/(\(.*?\)|ml\)( sku:[0-9]+)?)(\s+)?$/im, ''),
            price: DataCleaners::Parser::Price.parse(price_row[:price]),
            sale_price: DataCleaners::Parser::Price.parse(price_row[:special_price]),
            category: category(product),
            volume: parsed_volume,
            upc: DataCleaners::Parser::Upc.parse(product[:UPC] || product[:upc]),
            quantity: DataCleaners::Parser::Inventory.parse(price_row[:qty]),
            brand: product[:company],
            description: filter_description(product[:description]),
            type: wine_type(product),
            varietal: wine_varietal(product),
            subtype: wine_varietal(product),
            image_url: product[:image_link],
            ca_crv: parse_crv(product[:crv]),
            two_for_one: parse_two_for_one(price_row[:CBType]),
            region: product[:region],
            country: DataCleaners::Cleaner::Country.clean(product[:country]),
            appellation: product[:appellation],
            original_name: product[:name],
            trusted: true
          }
        end
      end
    end

    def parse_crv(crv)
      if crv.present?
        matched = crv.match(/(?<quantity>[0-9.]+)?:?(?<value>[0-9.]+)/)
        matched[:value]
      end
    end

    def parse_two_for_one(cb_type)
      if cb_type.present?
        case cb_type
        when /C/i
          BigDecimal(cb_type.scan(/\d+/).first) / 100
        when /\$/
          BigDecimal(cb_type.scan(/\d+/).first)
        end
      end
    end

    def string_to_volume(row)
      row = row.downcase

      match = row.match(/([0-9.]+)-?\s?pkc\s([0-9.]+)\s?([a-z]+)?/)
      if match
        container_count, volume_value, volume_unit = match.captures
        return {
          container_type: 'can',
          container_count: container_count || '',
          volume_value: volume_value || '',
          volume_unit: volume_unit || 'oz'
        }
      end

      match = row.match(/([0-9.]+)-?\s?pkb?\s([0-9.]+)\s?([a-z]+)?/)
      if match
        container_count, volume_value, volume_unit = match.captures
        return {
          container_type: 'bottle',
          container_count: container_count || '',
          volume_value: volume_value || '',
          volume_unit: volume_unit || 'oz'
        }
      end

      match = row.match(/([0-9.]+)\s+([^\s]+)?keg/)
      if match
        volume_value, volume_unit = match.captures
        return {
          container_type: 'keg',
          container_count: 1,
          volume_value: volume_value || '',
          volume_unit: volume_unit || ''
        }
      end

      match = row.match(/([0-9.]+)\s+([^\s]+)?\s*box/)
      if match
        volume_value, volume_unit = match.captures
        return {
          container_type: 'box',
          container_count: 1,
          volume_value: volume_value || '',
          volume_unit: volume_unit || ''
        }
      end

      # Keep this conversion even if such products are ignored later
      match = row.match(/([0-9.]+)\s(x)\s([0-9.]+)/)
      if match
        # do nothing
        return {
          container_type: '',
          container_count: '',
          volume_value: '',
          volume_unit: ''
        }
      end

      match = row.match(/([0-9.]+)\s+([a-z]+)\s*([a-z]+)?/)
      if match
        volume_value, volume_unit, container_type = match.captures
        container_type = 'bottle' if container_type.nil? && %w[ml oz gal ltr].include?(volume_unit)
        return {
          container_type: container_type || '',
          container_count: 1,
          volume_value: volume_value || '',
          volume_unit: volume_unit || ''
        }
      end

      # Keep this conversion even if such products are ignored later
      match = row.match(/(machine)?\s*([0-9.]+)?(each|pack|pk|set|single|large|medium|small|sm|bg|bag|gallon|bundle)/)
      if match
        container_type, volume_value, volume_unit = match.captures
        return {
          container_type: '',
          container_count: 1,
          volume_value: volume_value || '1',
          volume_unit: volume_unit || ''
        }
      end

      {
        container_type: '',
        container_count: '',
        volume_value: '',
        volume_unit: ''
      }
    end

    def normalize_volume_unit(volume_unit)
      return '' if volume_unit.blank?
      return 'OZ' if volume_unit.match?(/oz/i)
      return 'ML' if volume_unit.match?(/ml/i)
      return 'GAL' if volume_unit.match?(/gal/i)
      return 'LB' if volume_unit.match?(/lb/i)
      return 'L' if volume_unit.match?(/l/i)

      ''
    end

    def normalize_container_type(container_type)
      case container_type
      when 'BOTTLE', 'BAG', 'BOX', 'CAN', 'KEG'
        return container_type
      when 'BTL', 'GLASS'
        return 'BOTTLE'
      when 'BAGS'
        return 'BAG'
      end
      ''
    end

    def normalize_volume(vol)
      vol[:container_type] = vol[:container_type].upcase
      vol[:container_count] = vol[:container_count].to_i if vol[:container_count].present?
      vol[:volume_unit] = vol[:volume_unit].upcase
      vol[:volume_value] = vol[:volume_value].to_f if vol[:volume_value].present?

      vol[:volume_unit] = normalize_volume_unit(vol[:volume_unit])
      vol[:container_type] = normalize_container_type(vol[:container_type])

      vol
    end

    def humanize_volume(vol)
      trimmed_volume_value = vol[:volume_value] == vol[:volume_value].to_i ? vol[:volume_value].to_i : vol[:volume_value]
      volume_unit = vol[:volume_unit] == 'L' ? vol[:volume_unit] : vol[:volume_unit].downcase
      short_volume = "#{trimmed_volume_value}#{volume_unit}"

      volume_array = []
      volume_array.insert(-1, short_volume) if short_volume.present?
      volume_array.insert(-1, vol[:container_type].downcase.pluralize) if vol[:container_type].present? && vol[:container_count].present? && vol[:container_count] > 1
      volume_array.insert(0, "#{vol[:container_count]} pack" + (volume_array.empty? ? '' : ',')) if vol[:container_count].present? && vol[:container_count] > 1
      volume_array.join(' ')
    end

    def volume(row)
      item_volume = row[:size]

      v = normalize_volume(string_to_volume(item_volume))
      item_volume = humanize_volume(v)

      v.merge(
        {
          item_volume: item_volume
        }
      )
    end

    def category(row)
      category = String(row[:category])
      category = 'liquor' if /spirits/i =~ category
      category = 'beer' if /beer/i =~ category
      category = 'wine' if /wine/i =~ category
      category = 'mixers' if /(snacks|mixers)/ =~ category
      category
    end

    def wine_type(row)
      category = String(row[:category])
      type = row[:item_gorup]
      type = 'red' if /red wine/i =~ category
      type = 'white' if /white wine/i =~ category
      type = 'rose' if /rose/i =~ category
      type
    end

    def wine_varietal(row)
      category = String(row[:category])
      varietal = ''
      varietal = row[:varietal] if /wine/i =~ category
      varietal
    end

    def filter_description(text)
      String(text).downcase.include?('bevmo') ? nil : String(text).gsub(/^.*-\s/, '')
    end
  end
end
