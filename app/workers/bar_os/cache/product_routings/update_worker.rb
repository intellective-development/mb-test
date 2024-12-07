# frozen_string_literal: true

module BarOS
  module Cache
    module ProductRoutings
      # BarOS::Cache::ProductRoutings::UpdateWorker
      #
      # Worker that update the BarOS Pre Sale cache
      class UpdateWorker
        include Sidekiq::Worker
        include WorkerErrorHandling

        sidekiq_options queue: 'internal', lock: :until_executing

        def perform_with_error_handling(storefront_id)
          BarOS::Cache::ProductRoutings::Update.call(storefront_id: storefront_id)
        end
      end
    end
  end
end
