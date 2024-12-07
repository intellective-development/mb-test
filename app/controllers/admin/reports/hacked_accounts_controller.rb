class Admin::Reports::HackedAccountsController < Admin::Reports::BaseController
  def index
    @emailed_accounts =
      if params[:query].present?
        AuthenticatedSession
          .where.not(notified_value: nil)
          .joins(:user)
          .joins('JOIN registered_accounts ON registered_accounts.id = users.account_id')
          .where('email = ? or contact_email = ?', params[:query], params[:query])
          .order(created_at: :desc)
          .page(params[:page]).per(40)
      else
        AuthenticatedSession
          .where.not(notified_value: nil)
          .includes(user: [:account])
          .order(created_at: :desc)
          .page(params[:page]).per(40)
      end
  end
end
