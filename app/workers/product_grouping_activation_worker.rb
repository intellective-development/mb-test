class ProductGroupingActivationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(product_grouping_id)
    product_grouping = ProductSizeGrouping.find(product_grouping_id)
    product_grouping.products.each(&:activate)
  end
end
