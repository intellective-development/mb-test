# frozen_string_literal: true

module Google
  module Cloud
    class CredentialsFileError < Error
      def message
        'Unable to read the credential file specified by GOOGLE_APPLICATION_CREDENTIALS'
      end
    end
  end
end
