class Admin::BaseController < ApplicationController
  layout 'admin'

  helper :admin

  before_action :verify_admin, except: :unsu
  before_action :set_cache_headers

  private

  def ssl_required?
    ssl_supported?
  end

  def verify_admin
    raise CanCan::AccessDenied unless current_user&.admin?
  end

  def set_cache_headers
    response.headers['Cache-Control'] = 'no-cache, no-store'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Mon, 01 Jan 1990 00:00:00 GMT'
  end

  def verify_super_admin
    redirect_to admin_url unless current_user.super_admin?
  end
end
