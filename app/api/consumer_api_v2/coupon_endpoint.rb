# frozen_string_literal: true

# Coupon endpoint
class ConsumerAPIV2::CouponEndpoint < BaseAPIV2
  namespace :coupon do
    route_param :code do
      before do
        @coupon = Coupon.find_by(code: params[:code], storefront: storefront)
        raise ActiveRecord::RecordNotFound if @coupon.nil?
      end

      desc 'Retrieve coupon.', ConsumerAPIV2::DOC_AUTH_HEADER
      params do
        requires :code, type: String, allow_blank: false
        requires :storefront_id, type: String, allow_blank: false
      end
      get do
        present @coupon, with: ConsumerAPIV2::Entities::Coupon
      end
    end
  end
end
