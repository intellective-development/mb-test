# frozen_string_literal: true

module Memberships
  class SendMembershipPaymentCompletedEventWorker
    include Sidekiq::Worker
    include WorkerErrorHandling

    sidekiq_options \
      queue: 'sync_profile',
      retry: true,
      lock: :until_executing

    def perform_with_error_handling(membership_id)
      membership = Membership.find(membership_id)
      Segments::SegmentService.from(membership.storefront).membership_payment_completed(membership)
    end
  end
end
