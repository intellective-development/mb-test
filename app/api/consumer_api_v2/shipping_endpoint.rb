class ConsumerAPIV2::ShippingEndpoint < BaseAPIV2
  helpers Shared::Helpers::AddressHelpers
  helpers Shared::Helpers::AddressParamHelpers

  before do
    authenticate!
  end

  namespace :user do
    namespace :shipping do
      desc 'Creates a new shipping address for the user', ConsumerAPIV2::DOC_AUTH_HEADER
      params do
        use :create_address
      end
      post do
        validate_address_phone_requirement

        temp_params = if params[:state].present?
                        address_params(params).merge!(state_name: params[:state])
                      else
                        address_params(params)
                      end
        temp_params[:default] = @user.default_shipping_address.nil?

        address = AddressCreationService.new(@user, doorkeeper_application).create(temp_params)

        handle_opt_in

        if address
          present address, with: ConsumerAPIV2::Entities::Address
        else
          error!('Unable to save address', 400)
        end
      end
      route_param :id do
        before do
          @address = @user.addresses.active.find_by(id: params[:id])
          error!('Address not found', 404) if @address.nil?
        end
        desc 'Returns shipping address', ConsumerAPIV2::DOC_AUTH_HEADER
        params do
          requires :id, type: String
        end
        get do
          present @address, with: ConsumerAPIV2::Entities::Address
        end
        desc 'Update an address', ConsumerAPIV2::DOC_AUTH_HEADER
        params do
          requires :id,         type: String, allow_blank: false
          optional :name,       type: String, allow_blank: false
          optional :company,    type: String, allow_blank: true
          optional :address1,   type: String, allow_blank: false
          optional :address2,   type: String, allow_blank: true
          optional :city,       type: String, allow_blank: false
          optional :state,      type: String, allow_blank: false
          optional :zip_code,   type: String, regexp: /^(\d){5}/
          optional :phone,      type: String, allow_blank: false
          optional :latitude,   type: Float, allow_blank: true
          optional :longitude,  type: Float, allow_blank: true
          optional :default,    type: Boolean, allow_blank: true
          optional :sms_opt_in, type: Boolean, default: false
          optional :email_opt_in, type: Boolean, default: false
          at_least_one_of :name, :address1, :address2, :city, :state, :zip_code, :phone
        end
        put do
          address = if params[:state].present?
                      address_params(params).merge!(state_name: params[:state])
                    else
                      address_params(params)
                    end

          handle_opt_in

          new_address = Address.update_address(@address, address)

          present new_address, with: ConsumerAPIV2::Entities::Address
        end
        desc 'Delete an address', ConsumerAPIV2::DOC_AUTH_HEADER
        params do
          requires :id, type: String, allow_blank: false
        end
        delete do
          @address.deactivate

          present :success, true
        end
      end
    end
  end
end
