class Profile
  class AddProductImpressionWorker
    include Sidekiq::Worker
    include WorkerErrorHandling

    sidekiq_options retry: false,
                    queue: 'tracking'

    def perform_with_error_handling(profile_id, product_grouping_id)
      Profile::AddProductImpression.new(profile_id, product_grouping_id).call
    end
  end
end
