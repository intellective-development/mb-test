class OrderAdjustmentListener < Minibar::Listener::Base
  subscribe_to OrderAdjustment
  def financial_order_adjustment_created(order_adjustment_gid)
    # CR: This was 24.hours since 2017, CX says it worked instantly before, changing to 1 minute
    # I don't really know how it worked before, TODO: Monitor this
    ProcessFinancialOrderAdjustmentWorker.perform_at(1.minute.from_now, order_adjustment_gid)
  end
end
