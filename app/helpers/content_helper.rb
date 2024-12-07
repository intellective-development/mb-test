module ContentHelper
  def create_page_title(title)
    return 'Minibar Delivery – Wine, Spirits, and Beer Delivered.' if title.blank?
    return title if String(title).include?('Minibar Delivery')

    "#{title} - Minibar Delivery"
  end

  # This is used when presenting all the regions on the index page so that if any of
  # them redundantly include the state name it will be truncated.
  def trim_region_name(name)
    name.split(',')[0]
  end

  def format_address(address)
    "#{address.address1}, #{address.city}, #{address.state_name} #{address.zip_code}"
  end

  def format_date(date)
    date ? date.strftime('%m/%d/%Y') : ''
  end
end
