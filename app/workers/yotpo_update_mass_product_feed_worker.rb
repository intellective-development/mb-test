class YotpoUpdateMassProductFeedWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 5

  def perform_with_error_handling(params)
    batch_id = params['batch_id'] || jid
    current_page = params['page'] || 0

    success = YotpoService.new.update_mass_products(batch_id, current_page)
    raise 'YotpoUpdateMassProductFeedWorker error' unless success
  end
end
