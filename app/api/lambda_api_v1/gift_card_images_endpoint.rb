class LambdaAPIV1::GiftCardImagesEndpoint < LambdaAPIV1
  namespace :users do
    route_param :user_id do
      namespace :gift_card_images do
        desc 'Creates a new gift card image for the user', ConsumerAPIV2::DOC_AUTH_HEADER
        params do
          requires :correlation_id, type: String, desc: 'Unique image ID to relate the image to'
          optional :image_url, type: String, desc: 'Image URL of the gift card'
          optional :thumb_url, type: String, desc: 'Thumb URL of the gift card'
          at_least_one_of :image_url, :thumb_url
        end
        post do
          @user = User.find_by_id(params[:user_id])
          error!('User not found', 404) unless @user.present?
          gift_card_image = GiftCardImage.find_by_correlation_id(params[:correlation_id])
          gift_card_image ||= @user.gift_card_images.new({ status: :pending, correlation_id: params[:correlation_id] })
          gift_card_image.assign_attributes({ image_url: params[:image_url] }) if params[:image_url].present? && gift_card_image.image_url.blank?
          gift_card_image.assign_attributes({ thumb_url: params[:thumb_url] }) if params[:thumb_url].present? && gift_card_image.thumb_url.blank?
          error!('Image is invalid') unless gift_card_image.save
          present gift_card_image, with: LambdaAPIV1::Entities::GiftCardImage
        end
      end
    end
  end
end
