module Parsers
  class UncorkIt < BaseParser
    require 'net/ftp'
    require 'smarter_csv'

    def initialize(url)
      credentials = url.split('@@')
      @user = credentials[0]
      @password = credentials[1]
      @url = credentials[2]

      download_file

      @feed = File.open(@file)

      parse if @feed
    end

    def parse
      csv = SmarterCSV.process(@feed,                                  headers: true,
                                                                       row_sep: :auto,
                                                                       skip_blanks: true,
                                                                       verbose: true)

      csv.each do |row|
        sku       = row[:product_id]
        name      = DataCleaners::Cleaner::Name.clean(row[:name])
        volume    = DataCleaners::Parser::Volume.parse(row[:name])
        price     = row[:price]
        quantity  = row[:available] == 'Yes' ? 99_999 : 0
        category  = parse_uncork_category(row[:categories].to_s)
        type      = parse_uncork_type(row[:categories].to_s, category)
        varietal  = row[:categories].to_s.split('||').last

        next unless sku && price && quantity

        @products << {
          sku: sku.to_s,
          name: name,
          quantity: quantity,
          price: price,
          volume: volume,
          upc: DataCleaners::Parser::Upc.parse(row[:product_id]),
          category: category,
          type: type,
          original_name: (row[:name]).to_s
        }
      end
    end

    def parse_uncork_category(category)
      if category.include?('Wine')
        'wine'
      elsif category.include?('Beer')
        'beer'
      else
        'liquor'
      end
    end

    def parse_uncork_type(type, category)
      case category
      when 'wine'
        if type.include?('Red')
          'red'
        elsif type.include?('White')
          'white'
        elsif type.include?('Rose')
          'rose'
        elsif type.include?('Sparkling')
          'sparkling'
        end
      when 'liquor'
        type.split('||').first
      end
    end

    def download_file
      @file = connection.nlst.last
      connection.get(@file)
    end

    def connection
      @connection ||= Net::FTP.new(@url, {
                                     passive: true,
                                     username: @user,
                                     password: @password,
                                     ssl: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
                                   })
    end
  end
end
