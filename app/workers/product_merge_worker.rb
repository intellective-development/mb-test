class ProductMergeWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(source_product_id, destination_product_id, options = {}, user_id = nil)
    merge_service = ProductMergeService.new(source_product_id, destination_product_id, options, user_id)
    merge_service.merge!
  end
end
