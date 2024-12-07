# frozen_string_literal: true

class PackagingAPIV1::StorefrontsEndpoint::OrderEndpoint::PreviewsEndpoint < PackagingAPIV1
  helpers Shared::Helpers::StorefrontHelper

  resource :storefronts do
    route_param :permalink do
      before do
        @storefront = Storefront.find_by(permalink: sanitize_permalink(params[:permalink]))

        error!('Storefront not found', 404) if @storefront.nil?
      end

      namespace :order do
        desc 'Preview of the order tracking page'
        params do
          requires :secret, type: String, desc: 'Secret hash', allow_blank: false
        end

        get :preview do
          error!('Secret is invalid', 400) unless secret_valid?

          @order = DummyOrder.new

          status 200
          present @order.as_object
        end
      end
    end
  end

  helpers do
    def secret_valid?
      ActiveSupport::SecurityUtils.secure_compare(params[:secret], @storefront.tracking_page_order_preview_secret)
    end
  end
end
