class RegisteredAccountTokenRevocationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'default'

  def perform_with_error_handling(registered_account_id)
    RegisteredAccount.find(registered_account_id).tap do |account|
      RevokeTokenService.new(account).revoke_tokens
    end
  end
end
