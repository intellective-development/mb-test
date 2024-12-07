class Users::PasswordsController < Devise::PasswordsController
  layout 'minibar'

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  # def create
  #   super
  # end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)

    if resource && resource.errors.empty?
      Fraud::UpdatePasswordEvent.new(resource&.user, session, request, reason: '$forgot_password').call_async
      resource.ato_email_cleared
      resource.unlock_access! if unlockable?(resource)
      respond_to do |format|
        format.html { redirect_to login_url, notice: 'Your password has been reset' }
        format.json { render json: { message: 'Your password has been reset' } }
      end
    else
      Rails.logger.error('ERROR: Unable to reset password')

      respond_to do |format|
        format.html { render action: :edit }
        format.json { render json: { message: 'Unable to reset password' }, status: :bad_request }
      end
    end
  end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
