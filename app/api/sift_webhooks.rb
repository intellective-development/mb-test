class SiftWebhooks < BaseAPI
  helpers do
    def authenticate!
      postback_signature = headers['X-Sift-Science-Signature']

      digest = OpenSSL::Digest.new('sha1')
      calculated_hmac = OpenSSL::HMAC.hexdigest(digest, ENV['SIFT_WEBHOOK_SECRET_KEY'], env['api.request.input'])
      verification_signature = "sha1=#{calculated_hmac}"

      error!('Signature does not match', 401) unless verification_signature == postback_signature
    end
  end

  namespace :decision do
    desc 'Webhook endpoint for Sift Decision notifications.'
    params do
      requires :entity, type: Hash do
        requires :type, type: String
        requires :id,   type: String
      end
      requires :decision, type: Hash do
        requires :id, type: String
      end
      requires :time, type: Integer
    end
    before do
      authenticate!
    end
    post do
      Fraud::CreateSiftDecision.new(params[:entity], params[:decision]).call

      status 200
    end
  end
end
