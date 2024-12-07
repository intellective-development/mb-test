# frozen_string_literal: true

module BarOS
  module Cache
    # BarOS::Cache::ProductRoutings
    #
    # Concern to add baros product routings cache update on model callback
    module ProductRoutings
      extend ActiveSupport::Concern

      included do
        after_commit :update_bar_os_product_routings_cache
      end

      def update_bar_os_product_routings_cache
        return if ENV['BAR_OS_REDIS_URL'].blank?

        BarOS::Cache::ProductRoutings::UpdateWorker.perform_async(storefront_id)
      end
    end
  end
end
