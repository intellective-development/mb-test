# frozen_string_literal: true

module SevenEleven
  # Checks if the variant sale hours are compatible with the supplier sale hours
  class CheckProductsAlcoholSaleHoursCompatibility
    def initialize(supplier, variant, sale_hours)
      @supplier = supplier
      @variant = variant
      @sale_hours = sale_hours
    end

    def call
      return if @sale_hours.blank? || @supplier.blank? || @supplier.dashboard_type != Supplier::DashboardType::SEVEN_ELEVEN

      supplier_sale_hours = @supplier.shipping_methods.first&.hours_config
      return if supplier_sale_hours.blank?

      return if compatible_sale_hours?(supplier_sale_hours, sale_hours_to_hash(@sale_hours))

      Rails.logger.warn("[SevenEleven] Variant #{@variant.id} is not compatible with supplier #{@supplier.id} sale hours")
      @variant.soft_destroy
    end

    private

    # Checks if the supplier sale hours are compatible with the variant sale hours
    # @param supplier_sale_hours [Hash] the supplier sale hours
    # @param variant_sale_hours [Hash] the variant sale hours
    # @return [Boolean] true if the supplier sale hours are compatible with the variant sale hours, false otherwise
    def compatible_sale_hours?(supplier_sale_hours, variant_sale_hours)
      supplier_sale_hours.each do |day, wday_hours|
        return false if variant_sale_hours[day].blank?

        wday_compatible = true

        wday_hours.each do |s_start_time, s_end_time|
          supplier_start_time = Time.zone.parse(s_start_time.to_s)
          supplier_end_time = Time.zone.parse(s_end_time)

          next if supplier_end_time <= Time.zone.parse('4:00')

          compatible_times = variant_sale_hours[day].filter do |v_start_time, v_end_time|
            variant_start_time = Time.zone.parse(v_start_time.to_s)
            variant_end_time = Time.zone.parse(v_end_time)

            variant_start_time >= supplier_start_time && variant_end_time <= supplier_end_time
          end

          wday_compatible = false if compatible_times.none?
        end

        return false unless wday_compatible
      end

      true
    end

    def sale_hours_to_hash(sale_hours)
      hash = {}
      sale_hours.each do |sale_hour|
        key = sale_hour['day_index'].downcase.to_sym
        sale_hour['hours'].each do |hour|
          hash[key] ||= {}
          start_time = SevenEleven::ServiceHelper.convert_ampm_to_24h(hour['start_time'])
          end_time = SevenEleven::ServiceHelper.convert_ampm_to_24h(hour['end_time'])
          hash[key][start_time] = end_time
        end
      end
      hash
    end
  end
end
