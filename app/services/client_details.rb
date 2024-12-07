class ClientDetails < Struct.new(:ip_address, :device_udid, :ip_geolocation, :client, :platform)
  alias as_attributes to_h

  def initialize(request, doorkeeper_access_token)
    @request = request
    @token = doorkeeper_access_token
    @env = request&.env
    if @request && @env
      super(client_ip, client_udid, client_geolocation, api_client_name, client_platform)
    else
      super()
    end
  end

  private

  def api_client_name
    # Preferred method is to pass an access token on initialization. Alternate
    # supports the pre-wine_bouncer method.
    @api_client_name ||= @token&.application&.name || @env['api.token']&.application&.name
  end

  def client_geolocation
    @env['HTTP_CF_IPCOUNTRY']
  end

  def client_udid
    # Older clients use the x-minibar-device-id header whilst newer clients
    # (more correctluy) refer to it as the ad-id.
    device_id = @env['HTTP_X_MINIBAR_DEVICE_ID'] || @env['HTTP_X_MINIBAR_AD_ID']
    device_id == DeviceBlacklist::IOS_DEFAULT_UDID ? nil : device_id
  end

  def client_ip
    @env['HTTP_CF_CONNECTING_IP'] || @env['action_dispatch.remote_ip']&.to_s
  end

  def client_platform
    user_agent = String(@request.user_agent).downcase

    if /android/i.match?(String(api_client_name))
      'android'
    elsif /ios/i.match?(String(api_client_name))
      'iphone'
    elsif /android/.match?(user_agent)
      /(minibar|okhttp)/.match?(user_agent) ? 'android' : 'android_web'
    elsif /iphone|cfnetwork|darwin/.match?(user_agent)
      /minibar/.match?(user_agent) ? 'iphone' : 'iphone_web'
    elsif /ipad/.match?(user_agent)
      /minibar/.match?(user_agent) ? 'ipad' : 'ipad_web'
    elsif /ipod/.match?(user_agent)
      /minibar/.match?(user_agent) ? 'ipod' : 'ipod_web'
    else
      'web'
    end
  end
end
