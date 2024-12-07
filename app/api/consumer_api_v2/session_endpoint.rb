class ConsumerAPIV2::SessionEndpoint < BaseAPIV2
  helpers Shared::Helpers::AuthHelpers
  helpers Shared::Helpers::FraudHelpers
  helpers Shared::Helpers::SessionEndpointHelpers

  before do
    validate_device_udid!
  end

  namespace :user do
    desc 'Creates a new Minibar user account', ConsumerAPIV2::DOC_AUTH_HEADER
    params do
      use :user_registration
    end
    post do
      validate_application!
      set_temporary_password if anonymous?
      user, created = create_user(temp_password: @temp_password.present?)

      present user, with: ConsumerAPIV2::Entities::User, doorkeeper_application_id: doorkeeper_application&.id
    end

    desc 'Checks if we already have an registered account.', ConsumerAPIV2::DOC_AUTH_HEADER
    params do
      optional :email, type: String, regexp: CustomValidators::Emails.email_validator
      optional :phone, type: String, allow_blank: false
      exactly_one_of :email, :phone
    end
    get :find do
      authenticate!

      filter = params[:email].present? ? { email: params[:email] } : { phone_number: params[:phone] }
      account = RegisteredAccount.find_by({ storefront: storefront }.merge(filter))

      error!('User not found.', 404) if account.blank?

      register_response = { has_membership: Membership.active.where(user: account.user).present? }
      present register_response
    end

    namespace :liquid do
      desc 'Creates a new Auth0 user account', ConsumerAPIV2::DOC_AUTH_HEADER

      params do
        use :liquid_tokens
      end

      post do
        user, created = process_liquid_user

        present user, with: ConsumerAPIV2::Entities::User, doorkeeper_application_id: doorkeeper_application&.id
      end
    end

    desc 'Returns a user entity', ConsumerAPIV2::DOC_AUTH_HEADER
    get do
      authenticate!

      status 200
      present @user, with: ConsumerAPIV2::Entities::User, doorkeeper_application_id: doorkeeper_application&.id
    end

    desc 'Updates a user profile', ConsumerAPIV2::DOC_AUTH_HEADER
    params do
      optional :email, type: String, regexp: CustomValidators::Emails.email_validator
      optional :first_name, type: String, allow_blank: false, regexp: /\w{1,}/
      optional :last_name, type: String, allow_blank: false, regexp: /\w{1,}/
      optional :password, type: String, allow_blank: false
      optional :password_confirmation, type: String, allow_blank: false
      optional :one_signal_id, type: String, allow_blank: true
      optional :existing_password, type: String
      optional :birth_date, type: String
      optional :contact_email, type: String, regexp: CustomValidators::Emails.email_validator
      optional :contact_phone, type: String
    end
    put do
      authenticate!

      # In an ideal world we would use Grape's dependent parameters, but we need
      # to support older clients so we only validate `existing_password` if
      # the email or password is being changed.
      error!('Existing password is required.', 400) if should_reauthenticate? && params[:existing_password].blank?
      error!('Password is incorrect.', 400) if should_reauthenticate? && !@user.account.valid_password?(params[:existing_password])
      error!('Email address belongs to an existing user.', 400) if params[:email].present? && !available_or_current_email(params[:email])
      error!('Email address is associated with a cancelled account.', 400) if params[:contact_email].present? && cancelled_guest_accounts?(params[:contact_email])

      error!('Email address is required.', 400) if !Feature.flipper[:enable_no_email_user_update].enabled? && params[:email] && params[:email].blank?

      account_attributes = user_params.slice(:email, :contact_email, :password_confirmation, :password, :first_name, :last_name)
      account_attributes[:contact_phone_number] = params[:contact_phone] if params[:contact_phone].present?

      contact_email_exists = account_attributes.key?(:contact_email) && RegisteredAccount.exists?(email: account_attributes[:contact_email].downcase, storefront: storefront)
      error!('Email address belongs to an existing user.', 409) if contact_email_exists

      user_attributes = {
        account_attributes: account_attributes
      }
      user_attributes[:one_signal_id] = params[:one_signal_id] if params[:one_signal_id].present?
      user_attributes[:birth_date] = Date.strptime(params[:birth_date], '%Y-%m-%d').to_s(:db) if params[:birth_date].present?

      @user.update(user_attributes)
      error!("Validation error: #{@user.errors.full_messages.join(', ')}", 400) unless @user.errors.empty?

      status 200
      present @user, with: ConsumerAPIV2::Entities::User, doorkeeper_application_id: doorkeeper_application&.id
    end

    namespace :actions do
      desc 'Triggers a password reset', ConsumerAPIV2::DOC_AUTH_HEADER
      params do
        requires :email, type: String, regexp: CustomValidators::Emails.email_validator
      end
      post :reset_password do
        RegisteredAccount.send_reset_password_instructions(email: params[:email].downcase)
        status 200
        present :success, true
      end

      desc 'Logs in an existing Minibar user', ConsumerAPIV2::DOC_AUTH_HEADER
      params do
        use :user_credentials
      end
      post :authenticate do
        return present @user, with: ConsumerAPIV2::Entities::User, doorkeeper_application_id: doorkeeper_application&.id if @user && liquid_headers?

        present find_user_account.user, with: ConsumerAPIV2::Entities::User, doorkeeper_application_id: doorkeeper_application&.id
      end
    end

    put :password do
      authenticate!
      current_user = @user.account
      if current_user
        if current_user.guest?
          if current_user.reset_password(params[:password], params[:password_confirmation])
            current_user.email = current_user.contact_email
            current_user.contact_email = nil
            current_user.save!
            status 200
            # TODO: this is a temp workaround. It's not save to give user object here.
            present current_user.user, with: ConsumerAPIV2::Entities::User
          else
            error!(current_user.errors.full_messages.join(', '), 400)
          end
        else
          error!('User has already set a password.', 400)
        end
      else
        # TODO: JM: Shouldn't this be 404 "Account not found."?
        error!('User not found.', 400)
      end
    end

    post :auth0_accounts do
      authenticate!
      current_user = @user.account
      error!('User not found.', 404) unless current_user

      error!('User has already set a password.', 400) unless current_user.guest?

      error!(current_user.errors.full_messages.join(', '), 400) unless current_user.reset_password(params[:password], params[:password_confirmation])
      auth0_user = Auth0Utils::UserCreationService.call(storefront, current_user.email, current_user.password, current_user)

      current_user.login_providers << LoginProvider.new(key: 'liquid:auth0')
      current_user.update!(email: current_user.contact_email, contact_email: nil, uid: auth0_user['_id'], provider: 'liquid:auth0')

      present current_user.user, with: ConsumerAPIV2::Entities::User
    end

    namespace :passwordless do
      desc 'Send the login verification code to the user'
      params do
        optional :email
        optional :phone
        optional :login_type, values: %w[email sms]
        at_least_one_of :email, :phone
      end
      post :start do
        authenticate!
        current_account = @user.account
        error!('User not found.', 404) unless current_account

        login_type, login_providers =
          RegisteredAccounts::Passwordless::Start.new(storefront, current_account, params).call

        response = { login_type: login_type, login_providers: login_providers }
        present response, with: ConsumerAPIV2::Entities::Passwordless::Start
      end
    end

    namespace :comments do
      before do
        authenticate!
      end

      desc 'Returns a list of comments for a user'
      get do
        error!('User not found', 404) if @user.nil?

        present @user.comments, with: Shared::Entities::Comment
      end

      desc 'Add note to user'
      params do
        requires :note, type: String, desc: 'Note'
      end
      post do
        @user.comments.create!(note: params[:note], commentable_type: 'User', commentable_id: @user.id)

        present @user.comments, with: Shared::Entities::Comment
      end
    end
  end
end
