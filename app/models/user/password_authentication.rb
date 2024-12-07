class User
  module PasswordAuthentication
    extend ActiveSupport::Concern

    included do
      attr_accessor :allow_no_password

      # Include default devise modules. Others available are:
      # :confirmable, :timeoutable, :validatable and :omniauthable
      devise :database_authenticatable, :registerable, :encryptable,
             :recoverable, :rememberable, :trackable, :lockable

      auto_strip_attributes :first_name, :last_name, :email, squish: true

      validates :first_name,  presence: true, if: :registered_user?,
                              format: { with: CustomValidators::Names.name_validator },
                              length: { maximum: 30, minimum: 1 }
      validates :last_name,   presence: true, if: :registered_user?,
                              format: { with: CustomValidators::Names.name_validator },
                              length: { maximum: 35, minimum: 1 }
      validates :email,       presence: true,
                              uniqueness: { scope: :storefront_id, if: :email_changed? },
                              format: { with: CustomValidators::Emails.email_validator, if: :email_changed? },
                              length: { maximum: 255 }

      validates :password, confirmation: true
      validates :password, presence: true, length: { within: Devise.password_length }, allow_blank: true

      state_machine :state, initial: :active do
        state :inactive
        state :active
        state :canceled

        event :activate do
          transition all => :active, unless: :active?
        end

        event :cancel do
          transition from: %i[inactive active canceled], to: :canceled
        end

        after_transition to: :canceled, do: %i[reset_access_token publish_account_canceled]
      end

      # These are defined here because Devise loads all its stuff after
      # so we cannot override it's methods directly in the included module
      def password_required?
        if allow_no_password?
          password.present? || password_confirmation.present?
        else
          encrypted_password.blank?
        end
      end

      def send_devise_notification(notification, *args)
        UserDeviseMailWorker.perform_async(String(notification), id, *args)
      end

      protected :password_required?, :send_devise_notification
    end

    class_methods do
      def authenticate(email, password, storefront_id: Storefront::MINIBAR_ID)
        query = RegisteredAccount.where(storefront_id: storefront_id)

        account = query.find_for_authentication(email: email)
        account&.valid_password?(password) ? account : nil
      end

      def state_allows_login?(_state)
        !canceled?
      end
    end

    def publish_account_canceled
      broadcast_event(:canceled, prefix: true)
    end

    def registered_user?
      active?
    end

    def allow_no_password?
      @allow_no_password
    end

    def reset_access_token
      user.update(access_token: user.send(:generate_authentication_token))
    end

    def attributes
      super.merge(allow_no_password: @allow_no_password)
    end
  end
end
