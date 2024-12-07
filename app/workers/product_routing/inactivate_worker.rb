class ProductRouting::InactivateWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(product_routing_id)
    product_routing = ProductRouting.find(product_routing_id)
    return if product_routing.ends_at.nil? || product_routing.ends_at > DateTime.now

    ::ProductRoutings::Update.new(product_routing, { active: false }).call
  end
end
