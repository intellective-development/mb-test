class ConsumerAPIV2::PickupEndpoint < BaseAPIV2
  helpers do
    def pickup_detail_params(params)
      clean_params(params).permit(:name, :phone)
    end
  end

  before do
    authenticate!
  end

  namespace :user do
    namespace :pickup do
      desc 'Creates a new pickup details for the user', ConsumerAPIV2::DOC_AUTH_HEADER
      params do
        requires :name,       type: String, allow_blank: false
        requires :phone,      type: String, allow_blank: false
      end
      post do
        pickup_detail = PickupDetailCreationService.new(@user, doorkeeper_application).create(pickup_detail_params(params))

        if pickup_detail
          present pickup_detail, with: ConsumerAPIV2::Entities::PickupDetail
        else
          error!('Unable to save pickup details', 400)
        end
      end
      route_param :id do
        before do
          @pickup_detail = @user.pickup_details.find_by(id: params[:id])
          error!('Pickup details not found', 404) if @pickup_detail.nil?
        end
        desc 'Returns pickup details', ConsumerAPIV2::DOC_AUTH_HEADER
        params do
          requires :id, type: String
        end
        get do
          present @pickup_detail, with: ConsumerAPIV2::Entities::PickupDetail
        end
      end
    end
  end
end
