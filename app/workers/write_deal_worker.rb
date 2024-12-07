class WriteDealWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true, lock: :until_and_while_executing

  def perform_with_error_handling(payload)
    attributes = JiffyBag.decode(payload)

    deal = Deal.find_or_initialize_by(id: attributes[:id])
    user = RegisteredAccount.find_by(email: attributes[:user]['email'])&.user
    attributes.delete(:user)
    attributes[:user_id] = user.id.to_s
    deal.update!(attributes)
  end
end
