module LandingPageHelper
  def format_store_hours(open, close)
    if Time.zone.parse(close) - Time.zone.parse(open) <= 60
      'Closed'
    else
      "#{drop_leading_zeros(open)} - #{drop_leading_zeros(close)}"
    end
  end

  def drop_leading_zeros(time)
    time[0] == '0' ? time[1..] : time
  end

  def store_google_map_url(store_address)
    store_address.address1.parameterize(separator: '+')
    "https://maps.googleapis.com/maps/api/staticmap?center=#{store_address.address1.parameterize(separator: '+')}," \
        "#{store_address.city.parameterize(separator: '+')},#{store_address.state_name}," \
        "#{store_address.zip_code}&zoom=14&scale=2&size=700x225&" \
        "markers=#{store_address.address1.parameterize(separator: '+')}," \
        "#{store_address.city.parameterize(separator: '+')},#{store_address.state_name}," \
        "#{store_address.zip_code}&style=feature:poi|visibility:off&key=#{ENV['GOOGLE_MAPS_API_KEY']}"
  end
end
