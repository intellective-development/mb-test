class LambdaAPIV1 < BaseAPIV1
  format :json
  prefix 'api/lambda'
  version 'v1', using: :path

  before do
    authenticate!
  end

  helpers do
    def authenticate!
      return false if headers['Authorization'].nil?

      client_id, client_secret, lambda_key = headers['Authorization'].split(/\ /).last.to_s.split(':')

      error!('Unauthorized', 401) if [client_id, client_secret, lambda_key].any?(&:blank?)
      error!('Unauthorized', 401) if lambda_key != ENV['LAMBDA_API_KEY']

      @application = Doorkeeper::Application.find_by(uid: client_id, secret: client_secret)
      error!('Unauthorized', 401) if @application.blank?
    end
  end

  mount LambdaAPIV1::GiftCardImagesEndpoint
  mount LambdaAPIV1::ProductsEndpoint
end
