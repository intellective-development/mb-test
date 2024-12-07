class OAuthGrantsController < Devise::SessionsController
  layout 'oauth'

  # skip_before_action :check_for_lockup, raise: false

  def new
    session['oauth_return_to'] = params[:return_to] if params[:return_to]
    super
  end
end
