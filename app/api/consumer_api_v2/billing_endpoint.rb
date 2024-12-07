class ConsumerAPIV2::BillingEndpoint < BaseAPIV2
  helpers Shared::Helpers::BillingHelper, Shared::Helpers::BillingParamHelpers

  helpers do
    def load_payment_profile_update_link(params)
      @payment_profile_update_link = PaymentProfileUpdateLink.where(id: params[:id]).first!
      unless @payment_profile_update_link.present? &&
             @payment_profile_update_link.expire_at >= DateTime.now &&
             @payment_profile_update_link.used_at.nil?
        error!('Invalid payment profile update link', 400)
      end

      @payment_profile_update_link
    rescue ActiveRecord::RecordNotFound
      error!('Payment profile update link not found', 404)
    end
  end

  before do
    authenticate! if %r{^/user}.match(route.options[:namespace])
    validate_device_udid!
  end

  namespace :user do
    namespace :payment_profile do
      desc 'Creates a new payment profile for the user', ConsumerAPIV2::DOC_AUTH_HEADER
      params do
        use :billing_address
        use :cc_details
        use :billing_details
        optional :supplier_id, type: String, allow_blank: false, desc: 'ID of supplier whose merchant account will be used for verification. In the event of multiple supplers (comma separated) then the first will be used.'
        mutually_exclusive :payment_method_nonce, :cc_number
        mutually_exclusive :payment_method_nonce, :cc_exp_date
        mutually_exclusive :payment_method_nonce, :cc_cvv
        at_least_one_of :payment_method_nonce, :cc_number
        all_or_none_of :cc_number, :cc_exp_date, :cc_cvv
      end

      post do
        payment_profile = validate_and_create_payment_profile(params.merge({ url: request.url }), @user)
        error!(no_payment_profile_error_msg, 400) unless payment_profile

        present payment_profile, with: ConsumerAPIV2::Entities::PaymentProfile
      end

      route_param :id do
        before do
          @payment_profile = @user.payment_profiles.includes(:address).active.find_by(id: params[:id])
          error!('Payment Profile not found', 404) if @payment_profile.nil?
        end

        desc 'Returns a payment profile', ConsumerAPIV2::DOC_AUTH_HEADER
        params do
          requires :id, type: String, allow_blank: false
        end

        get do
          present @payment_profile, with: ConsumerAPIV2::Entities::PaymentProfile
        end

        desc 'Deletes a payment profile', ConsumerAPIV2::DOC_AUTH_HEADER
        params do
          requires :id, type: String, allow_blank: false
        end

        delete do
          @payment_profile.deactivate
          present :success, true
        end
        desc 'Sets payment profile as default', ConsumerAPIV2::DOC_AUTH_HEADER
        put :default do
          @payment_profile.update(default: true)
          present @payment_profile, with: ConsumerAPIV2::Entities::PaymentProfile
        end
      end
    end
  end

  namespace :payment_profile do
    namespace :update do
      route_param :id do
        desc 'Gets payment profile update link details', ConsumerAPIV2::DOC_AUTH_HEADER
        get do
          @payment_profile_update_link = load_payment_profile_update_link(params)

          present @payment_profile_update_link, with: ConsumerAPIV2::Entities::PaymentProfileUpdateLink
        end

        params do
          use :billing_address
          use :cc_details
          use :billing_details
          optional :supplier_id, type: String, allow_blank: false, desc: 'ID of supplier whose merchant account will be used for verification. In the event of multiple supplers (comma separated) then the first will be used.'
          mutually_exclusive :payment_method_nonce, :cc_number
          mutually_exclusive :payment_method_nonce, :cc_exp_date
          mutually_exclusive :payment_method_nonce, :cc_cvv
          at_least_one_of :payment_method_nonce, :cc_number
          all_or_none_of :cc_number, :cc_exp_date, :cc_cvv
        end

        desc 'Creates a new payment profile and replace it in the order related to link id'

        post do
          @payment_profile_update_link = load_payment_profile_update_link(params)
          order = @payment_profile_update_link.order
          payment_profile = validate_and_create_payment_profile(params, order.user)

          error!(no_payment_profile_error_msg, 400) unless payment_profile

          order.bill_address = payment_profile.address
          order.payment_profile = payment_profile
          order.save

          order_number = order.number

          shipments_with_exception = order.shipments.select(&:exception?)

          error!('Not able to charge order within this payment info.', 400) if Feature[:charge_after_payment_profile_update].enabled? && !Charges::ChargeOrderService.create_and_authorize_charges(order, shipments_with_exception)

          @payment_profile_update_link.used_at = Time.now.utc
          @payment_profile_update_link.save

          InternalAsanaNotificationWorker.perform_async({
                                                          tags: [AsanaService::BILLING_ISSUE_TAG_ID],
                                                          name: "Order #{order_number} - New Payment Profile Added",
                                                          notes: "Order: #{ENV['ADMIN_SERVER_URL']}/admin/fulfillment/orders/#{order_number}/edit"
                                                        })

          present payment_profile, with: ConsumerAPIV2::Entities::PaymentProfile
        end
      end
    end
  end
end
