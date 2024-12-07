class ConsumerAPIV2::ContentEndpoint < BaseAPIV2
  helpers Shared::Helpers::BrowseParamHelpers
  helpers Shared::Helpers::ContentParamHelpers
  helpers Shared::Helpers::SupplierHelpers

  desc 'Returns content for a specific placement.', ConsumerAPIV2::DOC_AUTH_HEADER
  params do
    use :content
  end
  get :content do
    placement = ContentPlacement.includes(:promotions).find_by(name: params[:placement])
    error!('Invalid Placement Name', 400) if placement.nil?
    Rails.logger.info "Get content by placement on Rails --> #{request.params.to_query}"

    # TODO: For logged in users, do we want to track what content was presented?
    #       Here I'm thinking its useful for stats and future content optimization activity.
    present placement.entity(params[:context], @user, params.dig(:context, :supplier_ids), request.headers['Authorization'])
  end

  desc 'Returns content for a specified page within the context of the specified supplier(s)', ConsumerAPIV2::DOC_AUTH_HEADER
  resource :supplier do
    route_param :supplier_id do
      params do
        use :shipping_state
        requires :supplier_id, type: String, desc: 'Supplier ID(s)'
        requires :page, type: String, desc: 'Name of page being requested'
        optional :context, type: Hash, default: {}
        optional :user_code, type: String, desc: 'Unique user identifier (referral code)' # Don't think we need to do anything here - we capture user from OAuth
      end
      before do
        load_suppliers(allow_empty: true)
      end
      get :content do
        screen = Content::MobileScreen.includes(:modules).active.find_by(name: params[:page])
        error!('Page not found', 404) if screen.nil?

        context = {
          user_id: @user&.id,
          supplier_ids: @supplier_ids,
          shipping_state: params[:shipping_state],
          auth_header: request.headers['Authorization']
        }.merge(params[:context]).symbolize_keys

        present screen, with: ConsumerAPIV2::Entities::ContentMobileScreen, context: context
      end
    end
  end

  desc 'Returns content for a specific popup.', ConsumerAPIV2::DOC_AUTH_HEADER
  get :popup do
    message = TopBannerMessage.find_or_initialize_by(id: 2)

    present message.as_json
  end

  desc 'Returns banners messages.', ConsumerAPIV2::DOC_AUTH_HEADER
  get :banners do
    top_banner = TopBannerMessage.find_or_initialize_by(id: 1)
    popup_banner = TopBannerMessage.find_or_initialize_by(id: 2)
    banners = { popup_banner: popup_banner, top_banner: top_banner }

    present banners.as_json
  end
end
