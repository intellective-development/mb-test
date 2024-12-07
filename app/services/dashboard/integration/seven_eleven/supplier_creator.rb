module Dashboard
  module Integration
    module SevenEleven
      class SupplierCreator
        include ApiMethods
        attr_accessor :seven_eleven_id, :supplier, :options

        DEFAULT_EMAIL_FOR_SUPPLIERS = 'services@minibardelivery.com'.freeze
        DEFAULT_DELIVERY_RADIUS = 8046.72 # Meters, this is 5 miles
        # Note: Class meant to be used in scripts by a dev, not tested enough for real user integrations/implementations
        # Missing things like API error catching, etc.

        def initialize(seven_eleven_id, options)
          @seven_eleven_id = seven_eleven_id
          @supplier = Supplier.find_by(dashboard_type: Supplier::DashboardType::SEVEN_ELEVEN, external_supplier_id: seven_eleven_id)
          process_options(options)
        end

        def process_options(options)
          raise 'Undefined supplier_type_id!' if options.supplier_type_id.blank?
          raise 'Undefined braintree_merchant_account_id!' if options.braintree_merchant_account_id.blank?
          raise 'Undefined delivery_service_id!' if options.delivery_service_id.blank?

          @options = options
        end

        def supplier_data
          @supplier_data ||= get_integration.store_details(seven_eleven_id).body
        end

        def valid?
          time_zone
          state
          region
          delivery_zone_polygon
          supplier_data
          true
        end

        def create_or_update!
          return unless valid?

          if @supplier.present?
            update_supplier!
          else
            create_supplier!
            create_shipping_method!
            create_address!
          end
          true
        end

        def update_supplier!
          @supplier.shipping_methods.first.update(hours_config: operating_hours)
          @supplier.delivery_hours.delete_all
          @supplier.update(delivery_hours_attributes: delivery_hours_hash)
        end

        def determine_supplier_type
          # TODO: fetch menu for store and determine 1 for wine & liquors, 2 for beer/anything else

          @options.supplier_type_id
        end

        def create_supplier!
          supplier_attributes = {
            name: "SevenEleven - #{seven_eleven_id}",
            email: DEFAULT_EMAIL_FOR_SUPPLIERS,
            braintree_merchant_account_id: @options.braintree_merchant_account_id,
            supplier_type_id: determine_supplier_type,
            timezone: time_zone,
            boost_factor: 0,
            region_id: region.id,
            permalink: "seveneleven-#{seven_eleven_id}",
            display_name: "7-Eleven #{seven_eleven_id}",
            external_supplier_id: seven_eleven_id,
            allow_substitution: false,
            emails: [DEFAULT_EMAIL_FOR_SUPPLIERS],
            dashboard_type: Supplier::DashboardType::SEVEN_ELEVEN,
            delivery_hours_attributes: delivery_hours_hash,
            integrated_inventory: true,
            show_substitution_ok: false,
            parent_id: @options&.parent_id,
            delivery_service_id: @options&.delivery_service_id
          }
          @supplier = Supplier.create(supplier_attributes)
          raise "Could not create supplier: #{@supplier.errors.full_messages}" unless @supplier.persisted?
        end

        def create_shipping_method!
          shipping_method_attributes = {
            shipping_type: 'on_demand',
            active: true,
            name: '7-Eleven',
            delivery_minimum: 15.0,
            delivery_threshold: nil,
            delivery_fee: 4.99,
            delivery_expectation: 'Delivery under an hour',
            allows_scheduling: false,
            scheduled_interval_size: 120,
            maximum_delivery_expectation: 60,
            hours_config: operating_hours,
            same_day_delivery: true,
            requires_scheduling: false,
            allows_tipping: true
          }
          shipping_method = supplier.shipping_methods.create(shipping_method_attributes)
          dz = DeliveryZonePolygon.create(shipping_method: shipping_method, value: delivery_zone_polygon.to_s, active: true)
          raise "Could not create shipping method: #{shipping_method.errors.full_messages}" unless shipping_method.persisted?
          raise "Could not create delivery zone: #{dz.errors.full_messages}" unless dz.persisted?
        end

        def create_address!
          address_attributes = {
            name: '7-Eleven',
            address1: supplier_data.address.street,
            city: supplier_data.address.city,
            state_id: state.id,
            state_name: supplier_data.address.state,
            zip_code: supplier_data.address.zip,
            phone: '855.711.7669 ext 3', # supplier_data.telephone,
            active: true,
            latitude: supplier_data.latitude,
            longitude: supplier_data.longitude,
            geocoded_at: Time.zone.now,
            address_purpose: 'supplier'
          }
          address = supplier.create_address(address_attributes)
          raise "Could not create address: #{address.errors.full_messages}" unless address.persisted?
        end

        def delivery_hours_hash
          time_wday = { sun: 0, mon: 1, tue: 2, wed: 3, thu: 4, fri: 5, sat: 6 }
          delivery_hours = []
          operating_hours.each do |day, time|
            delivery_hours << {
              wday: time_wday[day],
              off: false,
              starts_at: convert_hour_to_am_pm(time.keys[0]),
              ends_at: convert_hour_to_am_pm(time.values[0])
            }
          end
          delivery_hours
        end

        # PRIVATE

        def time_zone
          # https://time.is
          case supplier_data.address.state
          when 'CA', 'OR'
            'America/Los_Angeles'
          when 'TX', 'IL', 'MO'
            'America/Chicago'
          when 'FL', 'VA', 'NY', 'OH', 'CT', 'WA', 'MI', 'NC'
            'America/New_York'
          when 'CO'
            'America/Denver'
          when 'AZ'
            'America/Phoenix'
          else
            raise "No time zone found for #{supplier_data.address.state}"
          end
        end

        def state
          State.find_by_abbreviation(supplier_data.address.state) || raise("State #{supplier_data&.address&.state || 'unknown'} not found, create it.")
        end

        def region
          city_name = supplier_data&.address&.city&.titleize
          state_abbrev = supplier_data&.address&.state&.upcase
          city = City.joins(region: :state).find_by(name: city_name, states: { abbreviation: state_abbrev })
          raise "City #{city_name} not found in state #{state_abbrev}, create it." if city.blank?

          city.region || raise("No region found for city #{city_name}, create it.")
        end

        def delivery_zone_polygon
          params = HashWithIndifferentAccess.new({ type: 'circle', radius: DEFAULT_DELIVERY_RADIUS, center: { 'lat' => supplier_data.latitude, 'lng' => supplier_data.longitude } })
          polygon = Geo::GeometryBuilderService.new(params).build
          raise "Could not create polygon for supplier #{seven_eleven_id}" if polygon.nil?

          polygon
        end

        def operating_hours
          hours_config = supplier_data.operating_hours || supplier_data.opening_hours
          if hours_config.present?
            hours = hours_config.map do |hour|
              end_time = hour.end_time
              end_time = '23:59' if hour.end_time == '00:00' || hour.end_time == '00:00:00' # fix for midnight
              [hour.day_index.downcase.to_sym, { hour.start_time => end_time }]
            end
            ([hours[-1]] + hours[0..5]).to_h
          else
            # IF OPERATING HOURS IS NULL THEN IT MEANS STORE IS 24h
            { sun: { '00:00' => '23:59' }, mon: { '00:00' => '23:59' }, tue: { '00:00' => '23:59' }, wed: { '00:00' => '23:59' }, thu: { '00:00' => '23:59' }, fri: { '00:00' => '23:59' }, sat: { '00:00' => '23:59' } }
          end
        end

        def convert_hour_to_am_pm(hour)
          Time.parse(hour).strftime('%I:%M %P')
        end
      end
    end
  end
end
