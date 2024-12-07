# frozen_string_literal: true

module BarOS
  module Cache
    module PreSales
      # BarOS::Cache::PreSales::UpdateWorker
      #
      # Worker that update the BarOS Pre Sale cache
      class UpdateWorker
        include Sidekiq::Worker
        include WorkerErrorHandling

        sidekiq_options queue: 'internal', lock: :until_executing

        def perform_with_error_handling
          BarOS::Cache::PreSales::Update.call
        end
      end
    end
  end
end
