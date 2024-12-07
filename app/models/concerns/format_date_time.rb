module FormatDateTime
  def format_date(datetime)
    case datetime.to_date
    when Time.zone.today     then 'Today'
    when Time.zone.tomorrow  then 'Tomorrow'
    else datetime.strftime('%A, %b %-d') # e.g. Monday, Aug 15
    end
  end

  def format_time(datetime, meridian = true)
    time_string = datetime.strftime('%-l:%M %p') # e.g. 1:00pm
    if time_string == '12:00 pm'
      'noon'
    elsif time_string == '12:00 am'
      'midnight'
    elsif meridian
      time_string
    else
      datetime.strftime('%-l:%M') # e.g. 1:00
    end
  end

  def format_max_time(min, time_zone, delivery = true)
    case min
    when 0..30     then '30 minutes or less'
    when 31..60    then 'Under an hour'
    when 61..90    then '90 minutes or less'
    when 91..120   then '2 hours or less'
    else
      rounded_time = round_up_to_ten_minutes(Time.zone.now.in_time_zone(time_zone) + min.minutes)
      "#{format_date(rounded_time)} #{delivery ? 'by' : 'after'} #{format_time(rounded_time)}" # e.g. Today, by 4:10pm
    end
  end

  def round_up_to_ten_minutes(datetime)
    datetime.beginning_of_hour + ((datetime.min.to_f / 10).ceil * 10).minutes
  end

  def format_opening_time(time)
    "#{format_date(time)} after #{format_time(time)}" # e.g. Today, after noon || Monday, Aug 15, after 3:00pm
  end
end
