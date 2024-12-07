# frozen_string_literal: true

module Webhooks
  # This worker sends a webhook to the url specified in the storefront_webhook table
  class WebhookWorker
    include Sidekiq::Worker
    include WorkerErrorHandling

    sidekiq_options lock: :until_and_while_executing,
                    queue: 'backfill',
                    retry: 3

    def perform_with_error_handling(object_id)
      send_webhook(object_id)
    end
  end
end
