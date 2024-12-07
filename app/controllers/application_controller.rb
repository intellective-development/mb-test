class ApplicationController < ActionController::Base
  include CurrentUserSession
  include SentryNotifiable

  # skip_before_action :check_for_lockup, raise: false

  protect_from_forgery

  layout 'minibar'

  before_action :capture_utm
  before_action :set_paper_trail_whodunnit

  rescue_from CanCan::AccessDenied do |_exception|
    flash[:alert] = 'Sorry you are not allowed to do that.'
    if current_user&.admin?
      redirect_to :back
    else
      redirect_to root_url
    end
  end

  rescue_from ActiveRecord::DeleteRestrictionError do |exception|
    redirect_to :back, alert: exception.message
  end

  def append_info_to_payload(payload)
    super
    payload[:headers]    = request.headers
    payload[:params]     = request.params
    payload[:request_id] = request.uuid
    payload[:remote_ip]  = request.env['HTTP_CF_CONNECTING_IP']
    payload[:user_agent] = request.env['HTTP_USER_AGENT']
    payload[:user_id]    = current_user.id if current_user
  end

  def after_sign_in_path_for(_resource)
    if params[:return_to].present?
      params[:return_to]
    elsif params.dig(:registered_account, :return_to).present?
      params.dig(:registered_account, :return_to)
    elsif current_user.admin?
      '/admin'
    elsif current_user.supplier?
      'https://partners.minibardelivery.com/'
    else
      '/store'
    end
  end

  private

  def capture_utm
    cookies[:utm] = { value: utm.to_json, max_age: '2592000' } unless cookies[:utm]
  end

  def utm
    {
      utm_source: params[:utm_source],
      utm_campaign: params[:utm_campaign],
      utm_medium: params[:utm_medium],
      utm_term: params[:utm_term],
      utm_content: params[:utm_content]
    }
  end

  def pagination_page
    params[:page] ||= 1
    params[:page].to_i
  end

  def pagination_rows
    params[:rows] ||= 20
    params[:rows].to_i
  end

  def require_user
    if logged_out? || current_user.nil?
      store_return_location
      redirect_to login_url
    end
    # redirect_to login_url && store_return_location && return if logged_out?
  end

  def store_return_location
    # disallow return to login, logout, signup pages
    disallowed_urls = [login_url, logout_url]
    disallowed_urls.map! { |url| url[%r{/\w+$}] }
    session[:return_to] = request.url unless disallowed_urls.include?(request.url)
  end
end
