module Dashboard
  module Integration
    module SevenEleven
      module ApiMethods
        REDIS_PREFIX = 'SevenElevenDashboardService'.freeze

        def get_integration
          Dashboard::Integration::SevenEleven::Integration.new get_access_token
        end

        def get_access_token
          token_redis_key = "#{REDIS_PREFIX}:token"
          token = Redis.current&.get(token_redis_key)

          if token.blank?
            token = Dashboard::Integration::SevenEleven::Integration.authenticate(ENV['SEVEN_ELEVEN_NOW_CLIENT_ID'], ENV['SEVEN_ELEVEN_NOW_CLIENT_SECRET'])

            raise 'Can not retrieve access token from 7eleven API' if token.blank?

            Redis.current&.set(token_redis_key, token, ex: 72_000)
          end

          token
        end
      end
    end
  end
end
