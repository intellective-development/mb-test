class ConsumerAPIV2::GiftEndpoint < BaseAPIV2
  helpers Shared::Helpers::GiftParamHelpers

  helpers do
    def gift_params(params)
      clean_params(params).permit(:recipient_phone, :recipient_email, :recipient_name,
                                  :message)
    end
  end

  namespace :user do
    namespace :gift_detail do
      desc 'Creates new gift details belonging to the user', ConsumerAPIV2::DOC_AUTH_HEADER
      params do
        use :gift_detail_params
      end
      post do
        gift_details = GiftDetailCreationService.new(@user).create(gift_params(params))

        if gift_details
          present gift_details, with: ConsumerAPIV2::Entities::GiftDetails
        else
          error!('Unable to save gift details', 400)
        end
      end

      route_param :gift_detail_id do
        before do
          authenticate!

          @gift_details = GiftDetail.find_by(id: params[:gift_detail_id])

          error!('Gift Details Not Found', 404) if @gift_details.nil?
          error!('Gift Details Not Found', 404) if @gift_details.user_id && @gift_details.user_id != @user.id
        end

        desc 'Returns gift details', ConsumerAPIV2::DOC_AUTH_HEADER
        params do
          requires :gift_detail_id, type: String
        end
        get do
          present @gift_details, with: ConsumerAPIV2::Entities::GiftDetails
        end

        desc 'Updates existing gift details', ConsumerAPIV2::DOC_AUTH_HEADER
        params do
          requires :gift_detail_id, type: String
          use :edit_gift_detail_params
        end
        put do
          @gift_details.recipient_email = params[:recipient_email] if params[:recipient_email].present?
          @gift_details.recipient_phone = params[:recipient_phone] if params[:recipient_phone].present?
          @gift_details.recipient_name  = params[:recipient_name] if params[:recipient_name].present?
          @gift_details.message         = params[:message]         if params[:message].present?
          @gift_details.user            = @user                    unless @gift_details.user_id

          if @gift_details.save
            present @gift_details, with: ConsumerAPIV2::Entities::GiftDetails
          else
            message_sentry_and_log(@gift_details.errors.inspect, { gift_detail_id: @gift_details.id })
            error!('Unable to update gift details', 400)
          end
        end
      end
    end
  end
end
