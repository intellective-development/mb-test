class ProductGroupingTrimmedNameWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'backfill'

  def perform_with_error_handling
    ProductSizeGrouping.includes(:brand).where(trimmed_name: nil).find_each do |product_grouping|
      product_grouping.update_trimmed_name
      product_grouping.save
    end
  end
end
