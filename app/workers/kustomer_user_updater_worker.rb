class KustomerUserUpdaterWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options \
    queue: 'sync_profile',
    retry: true,
    lock: :until_executing

  def perform_with_error_handling(user_id)
    return unless (user = User.find_by(id: user_id))
    return if user.account.dummy?
    return unless ENV['KUSTOMER_URL'].present? && ENV['KUSTOMER_KEY'].present?

    service = KustomerService.new(ENV['KUSTOMER_URL'], ENV['KUSTOMER_KEY'])

    service.update_user user
  end
end
