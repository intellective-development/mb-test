module Dashboard
  module Integration
    module Specs
      class SupplierCreator
        attr_accessor :store_data, :supplier, :options

        DEFAULT_EMAIL_FOR_SUPPLIERS = 'services@minibardelivery.com'.freeze
        DEFAULT_DELIVERY_RADIUS = 8046.72 # Meters, this is 5 miles

        def initialize(store_data, options)
          @store_data = store_data
          @supplier = Supplier.find_by(dashboard_type: Supplier::DashboardType::SPECS, external_supplier_id: @store_data.store_id)
          process_options(options)
        end

        def process_options(options)
          raise 'Undefined supplier_type_id!' if options.supplier_type_id.blank?
          raise 'Undefined braintree_merchant_account_id!' if options.braintree_merchant_account_id.blank?
          raise 'Undefined delivery_service_id!' if options.delivery_service_id.blank?
          raise 'Undefined delivery_service_customer!' if options.delivery_service_customer.blank?

          @options = options
        end

        def valid?
          time_zone
          state
          region
          true
        end

        def create_or_update!
          return unless valid?

          if @supplier.present?
            update_supplier!
          else
            create_supplier!
            create_address!
            create_shipping_method!
          end
          true
        end

        def update_supplier!
          @supplier.shipping_methods.first.update({ hours_config: operating_hours })
          @supplier.delivery_hours.delete_all
          @supplier.update({ delivery_hours_attributes: delivery_hours_hash })
        end

        def get_display_name
          display_name = "Spec's Wines, Spirits & Finer Foods #{@store_data.store_id}"
          display_name = "Spec's #{@store_data.store_id} - #{@store_data.name.titleize}" unless @store_data.name.downcase.include? 'spec'

          display_name
        end

        def create_supplier!
          supplier_attributes = {
            name: "Specs #{@store_data.store_id}",
            email: DEFAULT_EMAIL_FOR_SUPPLIERS,
            braintree_merchant_account_id: @options.braintree_merchant_account_id,
            supplier_type_id: @options.supplier_type_id,
            timezone: time_zone,
            boost_factor: 0,
            region_id: region.id,
            permalink: "specs-#{@store_data.store_id}",
            display_name: get_display_name,
            external_supplier_id: @store_data.store_id,
            allow_substitution: false,
            emails: [DEFAULT_EMAIL_FOR_SUPPLIERS],
            dashboard_type: Supplier::DashboardType::SPECS,
            delivery_hours_attributes: delivery_hours_hash,
            integrated_inventory: true,
            show_substitution_ok: false,
            parent_id: @options&.parent_id,
            delivery_service_id: @options&.delivery_service_id,
            delivery_service_customer: @options&.delivery_service_customer
          }
          @supplier = Supplier.create(supplier_attributes)
          raise "Could not create supplier: #{@supplier.errors.full_messages}" unless @supplier.persisted?
        end

        def create_shipping_method!
          shipping_method_attributes = {
            shipping_type: 'on_demand',
            active: true,
            name: "Spec's - On Demand",
            delivery_minimum: 15.0,
            delivery_threshold: nil,
            delivery_fee: 4.99,
            delivery_expectation: 'Delivery in 60-120 minutes',
            allows_scheduling: false,
            scheduled_interval_size: 120,
            maximum_delivery_expectation: 120,
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
            name: get_display_name,
            address1: @store_data.address,
            city: @store_data.city,
            state_id: state.id,
            state_name: state.abbreviation,
            zip_code: @store_data.zipcode,
            phone: '(855) 487-0740',
            active: true,
            address_purpose: 'supplier'
          }

          address = supplier.create_address(address_attributes)
          raise "Could not create address: #{address.errors.full_messages}" unless address.persisted?

          address.geocode!
          raise 'Could not Geocode Address.', 500 unless address.geocodable?
        end

        def delivery_hours_hash
          time_wday = { sun: 0, mon: 1, tue: 2, wed: 3, thu: 4, fri: 5, sat: 6 }
          delivery_hours = []
          operating_hours.each do |day, time|
            delivery_hours << {
              wday: time_wday[day],
              off: (time_wday[day]).zero?,
              starts_at: convert_hour_to_am_pm(time.keys[0]),
              ends_at: convert_hour_to_am_pm(time.values[0])
            }
          end
          delivery_hours
        end

        # PRIVATE

        def time_zone
          # https://time.is
          case @store_data.state
          when 'CA', 'OR'
            'America/Los_Angeles'
          when 'TX', 'IL', 'MO'
            'America/Chicago'
          when 'FL', 'VA', 'NY', 'OH', 'CT'
            'America/New_York'
          when 'CO'
            'America/Denver'
          when 'AZ'
            'America/Phoenix'
          else
            raise "No time zone found for #{@store_data.state}"
          end
        end

        def state
          State.find_by_abbreviation(@store_data.state) || raise("State #{@store_data.state || 'unknown'} not found, create it.")
        end

        def region
          city_name = @store_data.city&.titleize
          state_abbrev = @store_data.state&.upcase
          city = City.joins(region: :state).find_by(name: city_name, states: { abbreviation: state_abbrev })
          raise "City #{city_name} not found in state #{state_abbrev}, create it." if city.blank?

          city.region || raise("No region found for city #{city_name}, create it.")
        end

        def delivery_zone_polygon
          params = HashWithIndifferentAccess.new({ type: 'circle', radius: DEFAULT_DELIVERY_RADIUS, center: { 'lat' => @supplier.address.latitude, 'lng' => @supplier.address.longitude } })
          polygon = Geo::GeometryBuilderService.new(params).build
          raise "Could not create polygon for supplier #{@store_data.store_id}" if polygon.nil?

          polygon
        end

        def operating_hours
          { sun: { '00:00' => '00:01' }, mon: { '11:00' => '20:00' }, tue: { '11:00' => '20:00' }, wed: { '11:00' => '20:00' }, thu: { '11:00' => '20:00' }, fri: { '11:00' => '20:00' }, sat: { '11:00' => '20:00' } }
        end

        def convert_hour_to_am_pm(hour)
          Time.parse(hour).strftime('%I:%M %P')
        end
      end
    end
  end
end
