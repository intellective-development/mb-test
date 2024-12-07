class RobotVerificationService
  require 'faraday'
  REDIS_PREFIX = 'RobotVerificationService'.freeze
  class << self
    def verify(request)
      return unless token(request)

      response = Faraday.post('https://www.google.com/recaptcha/api/siteverify', ssl: { verify: false }) do |req|
        req.params[:secret] = ENV['RECAPTCHA_V3_SECRET_KEY']
        req.params[:response] = token(request)
        req.params[:remoteip] = request.remote_ip
      end
      result = JSON.parse(response.body).symbolize_keys
      # if it is not a success we consider it is a bot
      result[:is_robot] = result[:success] && result[:score] < threshold || false
      # Make result accessible down to other request/session management
      request.params[:recaptcha_v3_result] = result
      result[:is_robot]
    end

    private

    def token(request)
      request.params[:recaptcha_v3_token] || request.params.dig(:registered_account, :recaptcha_v3_token)
    end

    def threshold
      Redis.current&.get("#{REDIS_PREFIX}:threshold")&.to_f || 0.5
    end
  end
end
