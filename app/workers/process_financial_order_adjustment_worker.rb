class ProcessFinancialOrderAdjustmentWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(order_adjustment)
    order_adjustment = GlobalID.find(order_adjustment) if order_adjustment.instance_of? String
    # TECH-4381: Added some logs in case the issue happens again
    Rails.logger.warn("processing_order_adjustment_#{order_adjustment.id}")

    order_adjustment.process
  end
end
