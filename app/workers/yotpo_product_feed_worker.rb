class YotpoProductFeedWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  ITEMS_PER_PAGE = 50

  def page
    YotpoWebhookLog.count
  end

  def variant_ids
    Variant.active.page(page).per(ITEMS_PER_PAGE).pluck(:id)
  end

  def perform_with_error_handling
    variants = variant_ids
    return unless variants.any?

    success = YotpoService.new.create_mass_products(variants)
    raise 'YotpoProductFeedWorkerWorker error' unless success
  end
end
