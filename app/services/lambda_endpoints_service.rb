# This service is used to call lambda function from the rails code.
class LambdaEndpointsService
  def self.call_lambda(uri, auth_header)
    @conn = Faraday.new(url: ENV['LAMBDA_API_URL'])

    response = @conn.get do |req|
      req.url(uri)
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = auth_header
    end

    JSON.parse(response.body) if response.status == 200
  end
end
