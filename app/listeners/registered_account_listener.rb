class RegisteredAccountListener < Minibar::Listener::Base
  subscribe_to RegisteredAccount

  def registered_account_canceled(registered_account)
    RegisteredAccountTokenRevocationWorker.perform_async(registered_account.id)
  end

  def registered_account_created(registered_account)
    RegisteredAccountWaitlistUnsubscribeWorker.perform_async(registered_account.id)
  end
end
