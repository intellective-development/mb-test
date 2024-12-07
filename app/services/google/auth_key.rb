module Google
  class AuthKey
    class << self
      def read
        # Simulates a File.open for Google Auth
        @read ||= {
          type: 'service_account',
          project_id: ENV['GOOGLE_SHOPPING_PROJECT_ID'],
          "private_key_id": ENV['GOOGLE_SHOPPING_PRIVATE_KEY_ID'],
          "private_key": get_private_key,
          "client_email": ENV['GOOGLE_SHOPPING_CLIENT_EMAIL'],
          "client_id": ENV['GOOGLE_SHOPPING_CLIENT_ID'],
          "auth_uri": 'https://accounts.google.com/o/oauth2/auth',
          "token_uri": 'https://oauth2.googleapis.com/token',
          "auth_provider_x509_cert_url": 'https://www.googleapis.com/oauth2/v1/certs',
          "client_x509_cert_url": ENV['GOOGLE_SHOPPING_CERT_URL']
        }.to_json
      end

      def get_private_key
        ENV['GOOGLE_SHOPPING_PRIVATE_KEY'].to_s.gsub(/\\n/, "\n")
      end
    end
  end
end
