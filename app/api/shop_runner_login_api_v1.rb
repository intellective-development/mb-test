class ShopRunnerAPIV1 < BaseAPIV1
  format :json
  prefix 'api/shoprunner'

  namespace :login do
    desc 'Endpoint for ShopRunner login'
    params do
      requires :username, type: String, allow_blank: false, desc: 'Shoprunner username.'
      requires :password, type: String, allow_blank: false, desc: 'Shoprunner password.'
    end
    post do
      result = ShopRunner::LoginService.new(params[:username], params[:password]).call
      status result[:error] ? 400 : 200
      present result
    end
  end
end
