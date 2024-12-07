module AuthenticateWithToken
  extend ::Grape::API::Helpers

  def authenticate_with_token!(token)
    error!('Unauthorized', 401) if headers['Authorization'].nil? || headers['Authorization'] != "Token #{token}"
  end
end
