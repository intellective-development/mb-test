module ApplicationHelper
  ### The next three helpers are great to use to add and remove nested attributes in forms.
  #  LOK AT THIS WEBPAGE FOR REFERENCE
  ## http://openmonkey.com/articles/2009/10/complex-nested-forms-with-rails-unobtrusive-jquery
  #  EXAMPLE USAGE!!
  #    <% form.fields_for :properties do |property_form| %>
  #     <%= render partial: '/admin/merchandise/add_property', locals: { f: property_form } %>
  #   <% end %>
  #    <p><%= add_child_link "New Property", :properties %></p>
  #    <%= new_child_fields_template(form, :properties, partial: '/admin/merchandise/add_property')%>

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'
    link_to title, { sort: column, direction: direction }, { class: css_class }
  end

  def remove_child_link(name, field)
    field.hidden_field(:_destroy) + link_to(name, 'javascript:void(0)', class: 'remove_child')
  end

  def add_child_link(name, association)
    link_to(name, 'javascript:void(0);', class: 'add_child', "data-association": association)
  end

  def add_child_button(name, association)
    link_to(name, 'javascript:void(0);', class: 'add_child button', "data-association": association)
  end

  def new_child_fields_template(form_builder, association, options = {})
    options[:object] ||= form_builder.object.class.reflect_on_association(association).klass.new
    options[:partial] ||= association.to_s.singularize
    options[:locals] ||= {}
    options[:form_builder_local] ||= :f
    options[:display] ||= 'none'

    content_tag(:div, id: "#{association}_fields_template", style: "display: #{options[:display]}") do
      form_builder.fields_for(association, options[:object], child_index: "new_#{association}") do |f|
        raw(render(partial: options[:partial], locals: { options[:form_builder_local] => f }.merge(options[:locals])))
      end
    end
  end

  def zipcode_name(zip)
    zip = '00000' if zip == '0' # Format for area gem
    zip.to_region
  end

  def generate_static_map_url(address, width = 400, height = 400)
    "http://maps.googleapis.com/maps/api/staticmap?markers=#{address.latitude},#{address.longitude}&zoom=17&size=#{width}x#{height}&key=#{Settings.google.maps_api_key}&style=element:geometry%7Ccolor:0xf5f5f5&style=element:labels.icon%7Cvisibility:off&style=element:labels.text.fill%7Ccolor:0x616161&style=element:labels.text.stroke%7Ccolor:0xf5f5f5&style=feature:administrative.land_parcel%7Celement:labels.text.fill%7Ccolor:0xbdbdbd&style=feature:poi%7Celement:geometry%7Ccolor:0xeeeeee&style=feature:poi%7Celement:labels.text.fill%7Ccolor:0x757575&style=feature:poi.park%7Celement:geometry%7Ccolor:0xe5e5e5&style=feature:poi.park%7Celement:labels.text.fill%7Ccolor:0x9e9e9e&style=feature:road%7Celement:geometry%7Ccolor:0xffffff&style=feature:road.arterial%7Celement:labels.text.fill%7Ccolor:0x757575&style=feature:road.highway%7Celement:geometry%7Ccolor:0xdadada&style=feature:road.highway%7Celement:labels.text.fill%7Ccolor:0x616161&style=feature:road.local%7Celement:labels.text.fill%7Ccolor:0x9e9e9e&style=feature:transit.line%7Celement:geometry%7Ccolor:0xe5e5e5&style=feature:transit.station%7Celement:geometry%7Ccolor:0xeeeeee&style=feature:water%7Celement:geometry%7Ccolor:0xc9c9c9&style=feature:water%7Celement:labels.text.fill%7Ccolor:0x9e9e9e"
  end

  def gravatar_url(email)
    "https://secure.gravatar.com/avatar/#{Digest::MD5.hexdigest(String(email).downcase)}&s=400&default=retro&r=x"
  end

  def touch_device?
    user_agent = request.headers['HTTP_USER_AGENT']
    user_agent.present? && user_agent =~ /\b(Android|iPod|iPhone|iPad|Windows Phone|Opera Mobi|Kindle|BackBerry|PlayBook)\b/i
  end

  def smartphone?
    user_agent = request.headers['HTTP_USER_AGENT']
    user_agent.present? && user_agent =~ /\b(iPod|iPhone|Android|Windows Phone|Opera Mobi|BackBerry|PlayBook)\b/i
  end

  def itunes_url
    'https://itunes.apple.com/us/app/minibar-delivery-wine-liquor/id720850888?mt=8&uo=4&at=11l5XB&ct=minibar'
  end

  def google_play_url
    'https://play.google.com/store/apps/details?id=minibar.android'
  end

  def hex_color(for_hex)
    "##{Digest::MD5.hexdigest(for_hex.to_s.downcase)[0..5]}"
  end

  def text_color(color)
    red   = color[1..2].hex
    green = color[3..4].hex
    blue  = color[5..6].hex
    (red + green + blue) > 440 ? '#000' : '#FFF'
  end

  def wrap_string(to_wrap)
    raw "\'#{to_wrap}\'"
  end

  def current_user_json(current_user)
    if current_user
      ConsumerAPIV2::Entities::User.new(current_user).to_json
    else
      {}.to_json
    end
  end

  def get_access_token(client_uid = nil)
    if current_registered_account
      WebAuthenticationService.resource_owner_token(client_uid, current_registered_account)&.token
    else
      WebAuthenticationService.client_credentials_token(client_uid)&.token
    end
  end

  def get_user_addresses(current_user)
    address_ids = current_user.orders.finished.order(created_at: :desc).limit(20).pluck(:ship_address_id).uniq if current_user
    if address_ids.present?
      # the group by followed by the map allows us to select the addresses in the order the addresses are entered in
      address_hash = Address.distinct.active.where(id: address_ids).group_by(&:id)

      # address may not be active, so in address_ids but not address_hash. try the first, compact the results
      sorted_addresses = address_ids.map { |id| address_hash[id]&.first }.compact

      @addresses = sorted_addresses.map { |a| JSON.parse(ConsumerAPIV2::Entities::ShippingAddress.new(a).to_json(type: :has_coordinates)) }.to_json
    end
  end

  def react_encode_props(props)
    Base64.strict_encode64(props.to_json)
  end

  def confirm_access_url(token)
    "#{root_url}confirm_access/#{token}"
  end

  def deny_access_url(token)
    "#{root_url}deny_access/#{token}"
  end

  def human_enum_options(enum)
    enum.keys.map { |key| [key.to_s.humanize, key] }
  end
end
