class SupplierUpdateNotificationJob < ActiveJob::Base
  queue_as :notifications_internal

  def perform(params)
    FormNotifier.supplier_update(params).deliver_now
  end
end
