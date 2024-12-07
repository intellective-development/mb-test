class Admin::Inventory::SuppliersController < Admin::BaseController
  helper_method :sort_column, :sort_direction, :delivery_hours
  respond_to :json, :html

  before_action :load_supplier, only: %i[activate edit update show delivered_map quality_score refresh_metadata send_promotion_zipcodes]

  def index
    @suppliers = Supplier.admin_grid(params).order("#{sort_column} #{sort_direction}")
                         .page(pagination_page)
                         .per(25)
  end

  def new
    @supplier = Supplier.new
    @address = @supplier.build_address
  end

  def create
    @supplier = Supplier.new(allowed_params.except(:delivery_hours_attributes))

    @supplier.delivery_hours_attributes = delivery_hours_params.values
    @supplier.active = false

    if @supplier.save
      update_employees # not really needed anyways, they have to add them in later
      redirect_to action: :index
    else
      @address = @supplier.address
      flash[:error] = 'The supplier could not be saved'
      render action: :new
    end
  end

  def edit
    @address = @supplier.address || @supplier.build_address

    @location = if @address.latitude.nil? || @address.longitude.nil?
                  nil
                else
                  Gmaps4rails.build_markers(@address) do |address, marker|
                    marker.lat address.latitude
                    marker.lng address.longitude
                  end
                end

    @feature_items = FeatureItem.all

    @supplier_logs = @supplier.versions.reorder(created_at: :desc).page(pagination_page).per(10)
    @delivery_logs = Version.where(item_type: 'DeliveryHour', item_id: @supplier.delivery_hours.ids).reorder(created_at: :desc).page(pagination_page).per(10)
    @address_logs = @address.versions.reorder(created_at: :desc).page(pagination_page).per(10)
    @notification_logs = Version.where(item_type: 'Supplier::NotificationMethod', item_id: @supplier.notification_methods.ids).reorder(created_at: :desc).page(pagination_page).per(10)
    @invoice_logs = Version.where(item_type: 'InvoiceTier', item_id: @supplier.invoice_tiers.ids).reorder(created_at: :desc).page(pagination_page).per(10)
    @business_logs = Version.where(item_type: 'BusinessSupplier', item_id: @supplier.business_suppliers.ids).reorder(created_at: :desc).page(pagination_page).per(10)

    @supplier.build_ship_station_credential if @supplier.ship_station_credential.nil? && @supplier.ship_station_dashboard?

    @delivery_services = DeliveryService.all
    @delivery_services = @delivery_services.where.not(name: 'UberDaas') unless Feature[:uber_daas_integration].enabled?
    @delivery_services = @delivery_services.collect { |service| [service.name, service.id] }

    params[:add_secondary_delivery_service] = @supplier.secondary_delivery_service_id.present?

    respond_to(&:html)
  end

  def update
    @supplier.attributes = allowed_params.except(:delivery_hours_attributes, :ship_station_credential_attributes)
    @supplier.delivery_hours_attributes = delivery_hours_params.values

    # We only want to set the feature items if it was saved on general tab.
    if params[:supplier][:name]
      @supplier.feature_item_ids = feature_items
      @supplier.profile.apple_pay_supported = params[:supplier][:apple_pay_supported]
      @supplier.profile.save

      save_ship_states
    end
    @supplier.config = JSON.parse(params[:supplier][:config]) if params[:supplier][:config].present?
    if params[:supplier][:emails].present?
      @supplier.emails = JSON.parse(params[:supplier][:emails] || '[]')
      @supplier.email = @supplier.emails.first # Backward-compatibility: remove it when no more ref to 'email'
    end

    @supplier.secondary_delivery_service_id = params[:add_secondary_delivery_service] ? DeliveryService.find_by(name: 'CartWheel')&.id : nil

    update_employees if params[:sub_form_notifications_employees].to_s.casecmp('update').zero?

    if @supplier.ship_station_dashboard? && allowed_params[:ship_station_credential_attributes].present?
      @supplier.ship_station_credential_attributes = allowed_params[:ship_station_credential_attributes]

      if @supplier.ship_station_credential.new_record? || @supplier.ship_station_credential.changed?
        valid_credentials = Dashboard::Integration::ShipStation::SubscribeWebhooks.new(@supplier.ship_station_credential).call
        unless valid_credentials
          flash[:alert] = 'ShipStation Credentials are invalid'
          return redirect_to action: :edit
        end
      end
    end

    if @supplier.save
      @supplier.ship_station_credential.destroy if @supplier.dashboard_type != Supplier::DashboardType::SHIP_STATION && @supplier.ship_station_credential.present?
      redirect_to action: :edit
    else
      @address = @supplier.address
      render action: :edit
    end
  end

  def show
    respond_with(@supplier)
  end

  def activate
    message = @supplier.ready_to_activate?
    if !@supplier.active? && message
      flash[:alert] = "Cannot Activate Supplier - #{message}"
      redirect_to action: :edit
    else
      @supplier.toggle_activation(current_user, params[:reason])
      redirect_to action: :index
    end
  end

  def delivered_map
    pin_images = {
      normal: 'https://maps.gstatic.com/mapfiles/ms2/micons/green-dot.png',
      late: 'http://i.stack.imgur.com/cdiAE.png'
    }

    @hash = Rails.cache.fetch "map-data-supplier-#{@supplier.id}", expires_in: 24.hours do
      @shipments = Shipment.includes(:order, order: :ship_address)
                           .where(supplier_id: @supplier.id)
                           .where(created_at: Date.today - 1.month..Date.today)
      Gmaps4rails.build_markers(@shipments) do |shipment, marker|
        marker.lat shipment.order.ship_address&.latitude
        marker.lng shipment.order.ship_address&.longitude
        marker.picture(url: shipment.determined_late? ? pin_images[:late] : pin_images[:normal],
                       width: 32,
                       height: 32)
        marker.infowindow "<p>#{shipment.updated_at.strftime('%b %d - %k:%M')}<br/>#{view_context.link_to(shipment.order_number, edit_admin_fulfillment_order_path(shipment.order_number))}</p>"
      end
    end
  end

  def quality_score
    @score_class = lambda do |score|
      if score >= 95
        'score-good'
      elsif score >= 80
        'score-medium'
      else
        'score-poor'
      end
    end
    # TODO: JM: If we don't want to touch this supplier in the service we could dup instead
    # which saves an extra find in the service. e.g. SupplierQuality.selection_score(@supplier.dup)
    # but in this case, I'd just send it the supplier and save the extra database hit.
    # I know it's not so clean, but it's faster.
    @scores = SupplierQuality.selection_score(@supplier.id)
  end

  def refresh_metadata
    SupplierProfileUpdateWorker.perform_async(@supplier.id)
    flash[:notice] = 'Supplier cache refreshing!'
    redirect_to action: :show
  end

  def reindex_products
    @supplier = Supplier.find(params[:id])
    @supplier.variants.find_each(&:reindex_async)

    flash[:notice] = "Reindexing products for #{@supplier.name}. This may take some time."
    redirect_to action: :show
  end

  def send_promotion_zipcodes
    if params[:delivery_zone_id].blank?
      flash[:alert] = 'You need to select the delivery zone in order to send a promotion.'
    else
      worker_params = { delivery_zone_id: params[:delivery_zone_id], promotion_type: params[:promotion_type] }
      ZipcodeCoveredPromotionWorker.perform_async(worker_params)
      flash[:notice] = 'Promotional event information will be sent to Iterable in a few minutes. It can take many minutes to process all users.'
    end
    redirect_to action: :edit
  end

  private

  def allowed_ship_states
    params.require(:supplier).permit(ship_states: [primary: {}, secondary: {}])
  end

  def allowed_params
    params
      .require(:supplier)
      .permit(
        :show_substitution_ok,
        :name, :emails, :zipcodes, :minibar_percent, :skip_state_shipping_tax, :braintree_merchant_account_id,
        :supplier_type_id, :timezone, :email_tip, :delivery_minimum, :allow_dtc_overlap, :engraving, :supports_graphic_engraving,
        :delivery_threshold, :delivery_fee, :delivery_expectation, :boost_factor, :temporary_boost_factor, :region_id,
        :region_list, :delegate_supplier_id, :delegate_invoice_supplier_id, :invoicing_enabled, :display_name, :integrated_inventory, :manual_inventory, :delivery_service_id,
        :trak_id, :onfleet_organization, :onfleet_autoassign_team, :order_note, :tdlinx_code, :notify_no_tracking_number,
        :delivery_service_customer, :delivery_service_client_id, :delivery_service_client_secret, :feature_items, :birthdate_required, :allow_substitution, :dashboard_type, :external_supplier_id,
        :lb_retailer_id, :daily_shipping_limit, :accepts_back_orders, :presale_eligible, :legacy_rb_paypal_supported, :exclude_minibar_storefront, :closed_hours_effective, fulfillment_service_ids: [],
                                                                                                                                                                            ship_station_credential_attributes: {},
                                                                                                                                                                            delivery_hours_attributes: %i[id wday starts_at ends_at],
                                                                                                                                                                            invoice_tiers_attributes: %i[id start_at end_at tier_min tier_max tier_type tier_value business_id],
                                                                                                                                                                            address_attributes: %i[name company address1 address2 city state_name zip_code address_purpose phone id],
                                                                                                                                                                            profile_attributes: %i[tag_list id delivery_mode],
                                                                                                                                                                            notification_methods_attributes: %i[id notification_type value label active _destroy]
      )
  end

  def load_supplier
    @supplier = Supplier.includes(:delivery_hours, :shipping_methods, :delivery_breaks, :ship_station_credential).find(params[:id])
  end

  def delivery_hours_params
    ::NestedAttributesParameters.new(allowed_params[:delivery_hours_attributes] || {})
  end

  def ship_states_params
    ::NestedAttributesParameters.new(allowed_ship_states[:ship_states]&.to_h || {})
  end

  def feature_items
    ::NestedAttributesParameters.new(params[:supplier][:feature_items] || [])
  end

  def update_employees
    params[:activates_employees] ||= []
    params[:destroys_employees] ||= []
    activate_employee_ids = params[:activates_employees].map(&:to_i)
    destroy_employee_ids = params[:destroys_employees].map(&:to_i)
    @supplier.update_employee_states(activate_employee_ids)
    @supplier.delete_employees(destroy_employee_ids)
  end

  def save_ship_states
    ::Suppliers::SupplierShipStates::Save.new(@supplier, ship_states_params).call
  end

  def sort_column
    Supplier.column_names.include?(params[:sort]) ? params[:sort] : 'name'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def delivery_hours(supplier)
    (Date.today.beginning_of_week..Date.today.end_of_week).map do |date|
      delivery = supplier.delivery_hours.find_by(wday: date.wday)
      "#{date.strftime('%A')}: #{delivery ? delivery.hours : 'Closed'}"
    end.compact
  end
end
