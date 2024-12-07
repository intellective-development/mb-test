class User
  module TokenAuthentication
    extend ActiveSupport::Concern

    included do
      before_save :ensure_authentication_token
    end

    #------------------------------------------
    # Class methods
    #------------------------------------------
    module ClassMethods
      def authenticate_with_token(token)
        where.not(access_token: nil).find_by(access_token: token)
      end
    end

    #------------------------------------------
    # Instance methods
    #------------------------------------------
    def ensure_authentication_token
      self.access_token = generate_authentication_token if access_token.blank?
    end

    private

    # TODO: JM: These could all do with being more secure.
    # i.e. store only a digest in the db so use the Devise::TokenGenerator instead
    # the plain text version.
    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless self.class.exists?(access_token: token)
      end
    end
  end
end
