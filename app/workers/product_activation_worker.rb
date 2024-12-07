class ProductActivationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(product_id)
    product = Product.find(product_id)
    product.inactive? ? product.activate : product.deactivate
    Rails.logger.error("Unable to toggle activation state for #{product_id}: #{product.errors.full_messages.join(' , ')}") unless product.errors.empty?
  end
end
