class ConsumerAPIV2::GiftCardImagesEndpoint < BaseAPIV2
  before do
    authenticate!
  end

  namespace :user do
    namespace :gift_card_images do
      desc 'Creates a new gift card image for the user', ConsumerAPIV2::DOC_AUTH_HEADER
      params do
        requires :correlation_id, type: String, desc: 'Unique image ID to relate the image to'
        optional :image_url, type: String, desc: 'Image URL of the gift card'
        optional :thumb_url, type: String, desc: 'Thumb URL of the gift card'
        at_least_one_of :image_url, :thumb_url
      end
      post do
        gift_card_image = GiftCardImage.find_by_correlation_id(params[:correlation_id])
        gift_card_image ||= @user.gift_card_images.new({ status: :pending, correlation_id: params[:correlation_id] })
        gift_card_image.assign_attributes({ image_url: params[:image_url] }) if params[:image_url].present? && gift_card_image.image_url.blank?
        gift_card_image.assign_attributes({ thumb_url: params[:thumb_url] }) if params[:thumb_url].present? && gift_card_image.thumb_url.blank?
        error!('Image is invalid') unless gift_card_image.save
        present gift_card_image, with: ConsumerAPIV2::Entities::GiftCardImage
      end

      desc 'Lists all gift card images of the user along with the variants'
      get do
        grouping = GiftCardTheme.where(is_custom: true).last&.product_size_grouping

        present :product_grouping, grouping.view.entity(business: storefront.business) if grouping
        present :user_themes, ConsumerAPIV2::Entities::GiftCardImage.represent(@user.gift_card_images.reverse)
      end

      route_param :id do
        desc 'Lists a specific gift card image of the user'
        get do
          image = @user.gift_card_images.find_by_id(params[:id])
          error!('Gift card image not found') if image.blank?
          present image, with: ConsumerAPIV2::Entities::GiftCardImage
        end

        desc 'Delete a specific gift card image of the user'
        delete do
          image = @user.gift_card_images.find_by_id(params[:id])
          if image.present?
            image.deleted_at = Time.zone.now
            image.save
          end
        end
      end
    end
  end
end
