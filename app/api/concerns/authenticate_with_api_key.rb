module AuthenticateWithApiKey
  extend ::Grape::API::Helpers

  def authenticate_with_api_key!
    error!('Unauthorized', 401) if headers['Api-Key'].nil? || api_key.nil?
  end

  def api_key
    @api_key ||= APIKey.find_by(token: headers['Api-Key'])
  end
end
