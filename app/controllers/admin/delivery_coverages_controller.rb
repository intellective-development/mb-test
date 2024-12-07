class Admin::DeliveryCoveragesController < Admin::BaseController
  helper_method :state_name_from_fips
  helper_method :state_code_from_fips

  def index
    @states = State.all.order('name')
    params.reject! { |_, v| v.blank? }
    params_copy = params.dup
    params_copy[:shipping_types] = params_copy[:shipping_types]&.map(&:to_i)
    # params_copy[:state] = state_fips_from_code(params_copy[:state])

    respond_to do |want|
      want.html { get_data(params_copy) }
      want.csv { send_data generate_csv(params_copy) }
    end
  end

  def coverage_map; end

  def get_active_delivery_zones_polygons
    render json: Geo::PointArrayService.new(nil).generate
  end

  private

  def get_data(params)
    @zipcodes = if params[:shipping_types].nil? || params[:shipping_types].include?(0)
                  CoveredZipcodesOnDemand.zipcodes(params)
                                         .page(params[:page])
                                         .without_count
                elsif params[:shipping_types].present? && params[:shipping_types].include?(2)
                  CoveredZipcodesShipped.zipcodes(params)
                                        .page(params[:page])
                                        .without_count
                else
                  []
                end
    @zipcodes
  end

  def parse_report_row(entry)
    # states = entry.states.map { |state| state_name_from_fips(state) }
    [entry.zipcode, entry.shipping_type&.humanize, entry.states.join(' - '), entry.cities.join(' - '), entry.contained_names.join(' - '), entry.shipping_type == 'on_demand' && entry.overlapped_names&.join(' - ')]
  end

  def generate_csv(params)
    CSV.generate(col_sep: "\t") do |csv|
      csv << ['zipcode', 'shipping type', 'states', 'cities', 'suppliers contained', 'suppliers overlapped']
      ::CoveredZipcodesOnDemand.zipcodes(params).each do |entry|
        csv << parse_report_row(entry)
      end
      ::CoveredZipcodesShipped.zipcodes(params).each do |entry|
        csv << parse_report_row(entry)
      end
    end
  end

  def state_name_from_fips(fips)
    DeliveryZoneState::NAMES[fips]
  end

  def state_code_from_fips(fips)
    DeliveryZoneState::CODES[fips]
  end

  def state_fips_from_code(code)
    DeliveryZoneState::FIPS[code]
  end
end
