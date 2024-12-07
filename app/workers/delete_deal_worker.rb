class DeleteDealWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true, lock: :until_and_while_executing

  def perform_with_error_handling(deal_id)
    Deal.where(id: deal_id).destroy_all
  end
end
