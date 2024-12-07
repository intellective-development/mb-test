# frozen_string_literal: true

module BarOS
  module Cache
    # BarOS::Cache::PreSales
    #
    # Concern to add baros pre sales cache update
    module PreSales
      extend ActiveSupport::Concern

      def update_bar_os_pre_sale_cache_async
        return if ENV['BAR_OS_REDIS_URL'].blank?

        BarOS::Cache::PreSales::UpdateWorker.perform_in(10.seconds)
      end
    end
  end
end
