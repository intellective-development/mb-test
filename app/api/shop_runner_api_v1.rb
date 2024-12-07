class ShopRunnerAPIV1 < BaseAPIV1
  format :json
  prefix 'shoprunner'

  namespace :validate do
    desc 'Endpoint for validating ShopRunner customer tokens.'
    params do
      requires :srtoken, type: String, allow_blank: true, desc: 'Unique code, used to validate and associate the request with an order.'
    end
    get do
      validation_result = ShopRunner::TokenValidationService.new(params[:srtoken]).call

      domain = Rails.env.production? ? '.minibardelivery.com' : nil

      if validation_result
        cookies[:sr_token] = {
          value: params[:srtoken],
          expires: Time.zone.now + 1.month,
          domain: domain,
          path: '/'
        }
      else
        cookies.delete :sr_token, { path: '/', domain: domain }
      end

      status 200
      content_type request.user_agent.index(/MSIE/) ? 'text/plain' : 'application/json'
      present :result, validation_result
    end
  end
end
