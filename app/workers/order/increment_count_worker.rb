class Order::IncrementCountWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_id)
    Order.includes(:order_amount).find(order_id).tap do |order|
      Count.increment('order_totals', order.taxed_total, order.completed_at.in_time_zone(ENV['TZ']).to_date)
    end
  end
end
