class Account::OverviewsController < Account::BaseController
  layout 'minibar'

  before_action :load_resource
  # TODO: JM: This is the way to do authorization.
  # load_and_authorize_resource :account, class_name: 'RegisteredAccount'

  def show; end

  def edit; end

  def update
    if @account.update(account_params)
      Fraud::UpdatePasswordEvent.new(@account.user, session, request, reason: '$user_update').call_async if @account.previous_changes[:encrypted_password]
      updated_account_details = updated_params
      Fraud::UpdateAccountEvent.new(@account.user, session, request, updated_account_details).call_async if updated_account_details.keys.any?
      redirect_to account_overview_url, notice: 'Successfully updated user.'
    else
      render :show
    end
  end

  private

  def load_resource
    @account = current_registered_account
  end

  def account_params
    params.require(:registered_account).permit(:password, :password_confirmation, :first_name, :last_name, :email)
  end

  def updated_params
    params = {}
    @account.previous_changes.except(:encrypted_password, :password_salt, :updated_at).each do |attr, (_old_value, new_value)|
      params[attr] = new_value
    end
    params
  end
end
