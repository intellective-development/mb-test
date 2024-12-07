module Dashboard
  module Integration
    module Bevmax
      class SupplierCreator
        attr_accessor :store_data, :supplier, :options

        DEFAULT_EMAIL_FOR_SUPPLIERS = 'services@minibardelivery.com'.freeze
        DEFAULT_DELIVERY_RADIUS = 8046.72 # Meters, this is 5 miles

        def initialize(store_data, options)
          @store_data = store_data
          @supplier = Supplier.find_by(dashboard_type: Supplier::DashboardType::BEVMAX, external_supplier_id: @store_data.store_id)
          process_options(options)
        end

        def process_options(options)
          raise 'Undefined supplier_type_id!' if options.supplier_type_id.blank?
          raise 'Undefined braintree_merchant_account_id!' if options.braintree_merchant_account_id.blank?

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

          supplier
        end

        def update_supplier!
          if (shipping_method = @supplier.shipping_methods.first)
            shipping_method.update({ hours_config: operating_hours })
          else
            create_shipping_method!
          end

          @supplier.delivery_hours.delete_all
          @supplier.update(delivery_hours_attributes: delivery_hours_hash)
        end

        def get_display_name
          display_name = "Bevmax Store #{@store_data.store_id}"
          display_name = "Bevmax #{@store_data.store_id} - #{@store_data.name.titleize}" unless @store_data.name.downcase.include? 'bevmax'

          display_name
        end

        def convert_hour_to_am_pm(hour)
          Time.parse(hour).strftime('%I:%M %P')
        end

        def operating_hours
          { sun: { '11:00' => '20:00' }, mon: { '11:00' => '20:00' }, tue: { '11:00' => '20:00' }, wed: { '11:00' => '20:00' }, thu: { '11:00' => '20:00' }, fri: { '11:00' => '20:00' }, sat: { '11:00' => '20:00' } }
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

        def create_supplier!
          supplier_attributes = {
            name: "BevMax Store #{@store_data.store_id}",
            email: DEFAULT_EMAIL_FOR_SUPPLIERS,
            braintree_merchant_account_id: @options.braintree_merchant_account_id,
            supplier_type_id: @options.supplier_type_id,
            timezone: time_zone,
            boost_factor: 0,
            region_id: region.id,
            permalink: "bevmax-#{@store_data.store_id}",
            display_name: get_display_name,
            external_supplier_id: @store_data.store_id,
            allow_substitution: false,
            emails: [DEFAULT_EMAIL_FOR_SUPPLIERS],
            dashboard_type: Supplier::DashboardType::BEVMAX,
            delivery_hours_attributes: delivery_hours_hash,
            integrated_inventory: true,
            show_substitution_ok: false,
            parent_id: @options&.parent_id
          }
          @supplier = Supplier.create(supplier_attributes)
          raise "Could not create supplier: #{@supplier.errors.full_messages}" unless @supplier.persisted?
        end

        def create_shipping_method!
          shipping_method_attributes = {
            shipping_type: 'shipped',
            active: true,
            name: 'BevMax',
            allows_scheduling: false,
            same_day_delivery: false,
            requires_scheduling: false,
            allows_tipping: false,
            delivery_expectation: 'Shipment (1-3 business days)'
          }
          shipping_method = supplier.shipping_methods.create(shipping_method_attributes)
          dz = DeliveryZoneState.create(shipping_method: shipping_method, value: state, active: true)
          raise "Could not create shipping method: #{shipping_method.errors.full_messages}" unless shipping_method.persisted?
          raise "Could not create delivery zone: #{dz.errors.full_messages}" unless dz.persisted?

          shipping_method
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
      end
    end
  end
end
