class SupplierAPIV2::SupplierEndpoint::CarrierAccountsEndpoint < BaseAPIV2
  include ShipEngineAdapter::Requests

  helpers do
    def ship_engine_adapter
      @ship_engine_adapter ||= ShipEngineAdapter.new
    end
  end

  before do
    authorize!
  end

  namespace :supplier do
    namespace :carrier_accounts do
      params do
        requires :carrier, type: String
        requires :account_details, type: Hash do
          optional :account_number, type: String, allow_blank: false
          optional :first_name, type: String, allow_blank: false
          optional :last_name, type: String, allow_blank: false
          optional :username, type: String, allow_blank: false
          optional :password, type: String, allow_blank: false
          optional :api_key, type: String, allow_blank: false
          optional :address, type: Hash do
            requires :address1, type: String, allow_blank: false
            optional :address2, type: String, allow_blank: true
            requires :city, type: String, allow_blank: false
            requires :state_name, type: String, allow_blank: false
            requires :zip_code, type: String, allow_blank: false
            requires :phone, type: String, allow_blank: false
          end
        end
      end

      desc 'Create carrier accounts on ShipEngine for a given supplier.'
      post do
        error!('Please setup carrier account on main or delegated store', 422) if current_supplier.delegating?

        carrier = params[:carrier]
        account_details = params[:account_details]

        address = current_supplier.address if account_details[:address].nil?
        address ||= OpenStruct.new(account_details[:address])

        begin
          res = ship_engine_adapter.connect_carrier_account(
            supplier: current_supplier,
            carrier: carrier,
            account_details: account_details
          )
        rescue ShipEngineAdapter::ShipEngineRedirectError => e
          Rails.warn("Redirecting to ShipEngine for carrier account setup: #{e.message}")
          redirect(e.message, permanent: true)
        rescue ShipEngineAdapter::UnsupportedCarrierError,
               ShipEngineAdapter::UnsuccessfulResponseError,
               ConnectCarrierAccount::AccountAlreadyConnectedForCarrierError,
               ArgumentError,
               KeyError => e
          error!(e.message, 400)
        end

        ship_engine_carrier_account = current_supplier.ship_engine_carrier_accounts.build(
          uuid: res.fetch('carrier_id'),
          carrier: carrier,
          address: {
            address1: address.address1,
            address2: address.address2,
            city: address.city,
            state_name: address.state_name,
            zip_code: address.zip_code,
            phone: address.phone
          }
        )

        if ship_engine_carrier_account.save
          status 201
          present ship_engine_carrier_account, with: SupplierAPIV2::Entities::ShipEngineCarrierAccount
        else
          error!('Unable to create a new ShipEngineCarrierAccount.', 422)
        end
      end

      get do
        status 200
        present current_supplier.ship_engine_carrier_accounts, with: SupplierAPIV2::Entities::ShipEngineCarrierAccount
      end

      route_param :id do
        before do
          @ship_engine_carrier_account = current_supplier.ship_engine_carrier_accounts.find_by(id: params[:id])

          error!('Carrier account not found', 404) if @ship_engine_carrier_account.nil?
        end

        desc 'Delete a carrier account'
        delete do
          error!('Carrier account can only be deleted from main or delegated store', 422) if current_supplier.delegating?

          begin
            ship_engine_adapter.disconnect_carrier_account(carrier: @ship_engine_carrier_account.carrier, carrier_id: @ship_engine_carrier_account.uuid)
          rescue ShipEngineAdapter::UnsuccessfulResponseError, ArgumentError => e
            error!(e.message, 400)
          end

          if @ship_engine_carrier_account.destroy
            body false
          else
            error!('An error occurred while deleting the given carrier account', 422)
          end
        end
      end
    end
  end
end
