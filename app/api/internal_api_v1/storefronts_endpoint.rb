# frozen_string_literal: true

class InternalAPIV1
  # InternalAPIV1::StorefrontsEndpoint
  class StorefrontsEndpoint < BaseAPIV1
    format :json

    helpers Shared::Helpers::StorefrontHelper,
            Shared::Helpers::StorefrontParamHelper

    resource :storefronts do
      desc 'Creates a new storefront'
      params do
        use :storefront_params
      end

      post do
        result = LiquidStorefronts::Create.new(params: final_permitted_storefront_params).call

        error!({ name: 'StorefrontCreationError', message: result.error }, 422) unless result.success?

        status 201
        present result.storefront, with: InternalAPIV1::Entities::Storefront
      end

      route_param :id do
        before do
          set_storefront
        end

        desc 'Deletes a given storefront'
        delete do
          if @storefront.destroy
            status 200
          else
            error!(@storefront.errors.full_messages.to_sentence, 422)
          end
        end
      end
    end

    helpers do
      def set_storefront
        @storefront = Storefront.liquidable.find_by(id: params[:id])

        error!('Storefront not found', 404) if @storefront.nil?
      end

      def final_permitted_storefront_params
        @final_permitted_storefront_params ||= permitted_storefront_params(params)
      end
    end
  end
end
