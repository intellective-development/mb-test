class SegmentIdentifyWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options \
    queue: 'sync_profile',
    retry: true,
    lock: :until_and_while_executing

  def perform_with_error_handling(user_id)
    return unless (user = User.find_by(id: user_id))
    return if user.account.dummy?

    storefront = user.account.storefront
    Segments::SegmentService.from(storefront).identify(user)
  end
end
