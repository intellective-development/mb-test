class Account::BaseController < ApplicationController
  before_action :require_user
  before_action :expire_all_browser_cache

  protected

  def ssl_required?
    ssl_supported?
  end
end
