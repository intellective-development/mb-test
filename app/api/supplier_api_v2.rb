require 'sentry/rack/capture_exceptions'
require 'doorkeeper/grape/helpers'

class SupplierAPIV2 < BaseAPIV2
  use Sentry::Rack::CaptureExceptions

  format :json
  prefix 'api/partners'
  version 'v2', using: :path

  error_formatter :json, ErrorFormatter

  helpers Doorkeeper::Grape::Helpers

  helpers do
    def authorize!
      error!('Unauthorized', 401) unless doorkeeper_token
      error!('User does not have supplier role', 401) unless current_user&.supplier?
    end

    # Find the user that owns the access token
    def resource_owner
      User.find_by(account_id: doorkeeper_token.resource_owner_id) if doorkeeper_token&.resource_owner_id
    end

    def current_supplier
      error!('Unauthorized', 401) unless resource_owner&.has_role?(:supplier) # don't allow unless user has supplier role

      @current_supplier ||= begin
        Supplier.find(resource_owner&.supplier_id)
      rescue ActiveRecord::RecordNotFound
        error!('No Supplier', 400)
      end
    end

    def current_supplier_ids
      current_supplier.delegate_supplier_ids.unshift(current_supplier.id)
    end

    def current_user
      @current_user ||= begin
        user = resource_owner || nil

        Sentry.set_user(id: user.id, email: user.email, name: user.name) if user

        user
      end
      error!('No user', 401) if @current_user.nil?

      @current_user
    end

    def api_client_name
      doorkeeper_access_token&.application&.name
    end

    def clean_params(params)
      ActionController::Parameters.new(params)
    end

    def parse_order_sort_column(sort)
      case sort
      when 'id' || 'number'
        'shipments.id'
      when 'customer_name'
        'orders.email'
      when 'state'
        'shipments.state'
      else
        'shipments.created_at'
      end
    end
  end

  mount SupplierAPIV2::ReportingEndpoint
  mount SupplierAPIV2::SettingsEndpoint
  mount SupplierAPIV2::ShipmentEndpoint
  mount SupplierAPIV2::ShipmentEndpoint::PackagesEndpoint
  mount SupplierAPIV2::ShipmentEndpoint::PackagesEndpoint::RateEstimationsEndpoint
  mount SupplierAPIV2::ShipmentsEndpoint::PackagesEndpoint::LabelsEndpoint
  mount SupplierAPIV2::SupplierEndpoint
  mount SupplierAPIV2::SupplierEndpoint::CarrierAccountsEndpoint
  mount SupplierAPIV2::SupplierEndpoint::ShipmentsEndpoint
  mount SupplierAPIV2::SupplierEndpoint::PackageSizePresetsEndpoint
  mount SupplierAPIV2::SupplierEndpoint::HolidaysEndpoint
  mount SupplierAPIV2::VariantEndpoint
  mount SupplierAPIV2::VariantsEndpoint
  mount SupplierAPIV2::InventoryEndpoint
  mount SupplierAPIV2::CustomTagEndpoint
  mount SupplierAPIV2::ShipmentEndpoint::CustomTagEndpoint
end
