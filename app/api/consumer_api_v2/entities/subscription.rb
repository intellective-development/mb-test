class ConsumerAPIV2::Entities::Subscription < Grape::Entity
  expose :id, :interval, :next_order_date, :state
  expose :base_order_number do |subscription|
    subscription.base_order.number
  end
end
