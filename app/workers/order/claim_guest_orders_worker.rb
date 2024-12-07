class Order::ClaimGuestOrdersWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal',
                  lock: :until_and_while_executing

  def perform(registered_account_id)
    account = RegisteredAccount.find_by(id: registered_account_id)
    return if account.blank?
    return if account.user.guest_by_email?

    Order::ClaimGuestOrders.new(account).call
  end
end
