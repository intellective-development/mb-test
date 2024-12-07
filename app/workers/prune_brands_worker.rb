class PruneBrandsWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  def perform_with_error_handling
    PruneBrandsService.new.call
  end
end
