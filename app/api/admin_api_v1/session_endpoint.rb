class AdminAPIV1::SessionEndpoint < BaseAPIV1
  namespace :login do
    desc 'Logs in an existing Minibar admin user'
    params do
      requires :email,    type: String, regexp: CustomValidators::Emails.email_validator
      requires :password, type: String, allow_blank: false
    end

    post :authenticate do
      email = params[:email].downcase
      password = params[:password]

      account = RegisteredAccount.authenticate(email, password)
      if account
        error!('Account Disabled', 403) if account.canceled?
        error!('Unauthorized', 403) unless account.user.admin?
      elsif RegisteredAccount.exists?(email: email)
        error!('Invalid Password', 400)
      else
        error!('Invalid Email Address', 404)
      end
      present account.user, with: AdminAPIV1::Entities::User
    end
  end
end
