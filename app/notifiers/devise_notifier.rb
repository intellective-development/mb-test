class DeviseNotifier < Devise::Mailer
  include MinibarMailer
  include Devise::Controllers::UrlHelpers

  default template_path: 'devise/notifier'

  layout 'email_foundation_2'

  def reset_password_instructions(record, token, opts = {})
    opts[:subject] = format_subject('Password Reset Instructions')
    opts[:to] = record.email_address_with_name

    super
  end

  def account_takeover_warning_instructions(record, authenticated_session, opts = {})
    @token = authenticated_session.notification_token
    @device = device_from_user_agent(authenticated_session.user_agent)
    @location = location_from_ip(authenticated_session.ip)
    @time = et_from_utc(authenticated_session.created_at)
    opts[:to] = record.email_address_with_name
    opts[:from] = 'Minibar Delivery <info@minibardelivery.com>'
    devise_mail(record, :account_takeover_warning_instructions, opts)
  end

  def account_takeover_alert_instructions(record, authenticated_session, opts = {})
    @token = authenticated_session.notification_token
    @device = device_from_user_agent(authenticated_session.user_agent)
    @location = location_from_ip(authenticated_session.ip)
    @time = et_from_utc(authenticated_session.created_at)
    opts[:to] = record.email_address_with_name
    opts[:from] = 'Minibar Delivery <info@minibardelivery.com>'
    devise_mail(record, :account_takeover_alert_instructions, opts)
  end

  private

  def device_from_user_agent(http_user_agent)
    user_agent = UserAgent.parse(http_user_agent)
    if user_agent.browser == 'Minibar'
      'Mobile Application'
    else
      "#{user_agent.browser} on #{user_agent.platform}"
    end
  end

  def et_from_utc(time)
    time.in_time_zone('Eastern Time (US & Canada)').strftime('%b %-d, %Y, %I:%M %p (ET)')
  end

  def location_from_ip(remote_ip)
    location = Geocoder.search(remote_ip).first
    if location
      "#{location.city}, #{location.country} (#{remote_ip})"
    else
      remote_ip.to_s
    end
  end
end
