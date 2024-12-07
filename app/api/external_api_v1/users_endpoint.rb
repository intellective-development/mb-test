class ExternalAPIV1::UsersEndpoint < ExternalAPIV1
  namespace :users do
    desc 'Returns a user by given email or phone number.'
    params do
      optional :email, type: String, desc: 'Email'
      optional :phone_number, type: String, desc: 'Phone Number'
    end
    get do
      error!("Please provide 'email' or 'phone_number' params in order to find the user that you're looking for", 400) if params[:email].nil? && params[:phone_number].nil?

      @user = if params[:email].present?
                RegisteredAccount.find_by(email: params[:email])&.user
              elsif params[:phone_number].present?
                User.joins(:shipping_addresses).find_by(addresses: { phone: params[:phone_number] })
              end

      error!('User not found', 404) if @user.nil?

      status 200
      present @user, with: ExternalAPIV1::Entities::User
    end
  end
end
