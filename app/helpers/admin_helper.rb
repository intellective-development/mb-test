# rubocop:disable  Metrics/ModuleLength
module AdminHelper
  PRODUCT_VOLUMES = %w[ML OZ L GAL LB PINT EA XXS XSM SML MED LRG XLG XXL 3XL 4XL -3XL -4XL].freeze
  def show_release_info?
    ENV['HEROKU_RELEASE_CREATED_AT'] && ENV['HEROKU_SLUG_COMMIT']
  end

  def hash_table_tag(hash)
    case hash
    when Hash
      html = content_tag(:table) do
        table_contents = ''
        hash.each_pair do |k, v|
          table_contents << content_tag(:tr) do
            row_contents = ''
            row_contents << content_tag(:th, k)
            row_contents << content_tag(:td, hash_table_tag(v))
            row_contents.html_safe
          end
        end
        table_contents.html_safe
      end.html_safe
    when Array
      content_tag(:ul) do
        ul_contents = ''
        hash.each do |v|
          ul_contents << content_tag(:li, hash_table_tag(v))
        end
        ul_contents.html_safe
      end
    else
      url_tag_helper(hash)
    end
  end

  def nested_dom_id(*objects)
    objects.map { |object| object.is_a?(ActiveRecord::Base) ? dom_id(object) : object.to_s }.join('_')
  end

  def pending_products?(product_grouping)
    product_grouping.products.pending.exists?
  end

  def order_row_style(order)
    return 'late' if order.verifying? || order.shipments.any?(&:exception?)

    ''
  end

  def expected_delivery_time(shipment)
    if shipment.scheduled_for.present?
      [shipment.scheduled_for, shipment.scheduled_for + shipment.shipping_method.scheduled_interval_size.minutes]
    else
      base = (shipment.shipping_method.closed?(shipment.order.completed_at) ? shipment.shipping_method.opens_at : shipment.order.completed_at)
      [base + shipment.shipping_method.maximum_delivery_expectation.minutes]
    end
  end

  def format_delivery_time(shipment)
    start_time, end_time = expected_delivery_time(shipment)
    return start_time.in_time_zone(shipment.supplier.timezone).strftime('%I:%M %p') if end_time.blank?

    "#{start_time.in_time_zone(shipment.supplier.timezone).strftime('%I:%M')}-#{end_time.in_time_zone(shipment.supplier.timezone).strftime('%I:%M %p')}"
  end

  def format_delivery_date(shipment)
    expected_delivery_time(shipment).first.in_time_zone(shipment.supplier.timezone).strftime('%A, %D')
  end

  def url_tag_helper(string)
    String(string).starts_with?('http') ? link_to(string, string, target: '_blank', rel: 'noopener') : string
  end

  def format_hierarchy(product, join_char = '>')
    return nil unless product

    [product.hierarchy_category_name, product.hierarchy_type_name, product.hierarchy_subtype_name].compact.join(" #{join_char} ")
  end

  def format_price_range(product)
    price_range = product.price_range.uniq
    return number_to_currency(price_range[0]) if price_range.length == 1

    "#{number_to_currency(price_range[0])} - #{number_to_currency(price_range[1])}"
  end

  def format_brand_name(product_grouping)
    [product_grouping&.brand&.parent&.name, product_grouping&.brand&.name].compact.join(' &rarr; ')
  end

  def chargeback_label_color(dispute)
    case dispute.status
    when 'won' then 'success'
    when 'lost' then 'alert'
    else
      'secondary'
    end
  end

  def fraud_score_tooltip(results)
    text = ''
    results.each do |k, v|
      text += "#{v ? '<strong style="color:yellow">' : ''} #{I18n.t("fraud_score.#{k}", default: k)}: #{v} #{v ? '</strong>' : ''} <br>"
    end
    text
  end

  def applied_deals_tooltip(deals)
    deals.map do |deal|
      "#{deal.title} - #{number_to_currency(deal.value)}"
    end.join('<br>')
  end

  def status_tooltip(order)
    if order.scheduled?
      "This order is scheduled for delivery on #{display_time(order.scheduled_for, order.order_suppliers.first)}."
    elsif order.confirmed?
      "This order was confirmed on #{display_time(order.confirmed_at, order.order_suppliers.first)}."
    elsif order.delivered?
      'This order was delivered.'
    elsif order.canceled?
      "This order was canceled on #{display_time(order.cancelled_at, order.order_suppliers.first)}."
    else
      "This order was placed on #{display_time(order.completed_at, order.order_suppliers.first)}."
    end
  end

  def timestamp(time)
    time.nil? ? '' : time.strftime('%d/%b/%Y %H:%M:%S %z')
  end

  def storefronts_dropdown_items
    top_titles = [
      'ReserveBar',
      'ReserveBar - Concierge',
      'Minibar',
      'Get Stocked'
    ]
    all = Storefront.active.order(:name).pluck(:name, :id)
    top = all.select { |name, _| top_titles.include?(name) }
    top = top.sort_by { |name, _| top_titles.index(name) }
    top + [nil] + all # adding a nil here so it works as a separator within html select tag
  end

  def supplier_dashboard_type_dropdown_items(selected = nil)
    options = [['All', nil]]
    Supplier::DashboardType::DASHBOARD_TYPES.each do |type|
      options << [type.titleize, type]
    end
    options_for_select(options, selected)
  end

  def membership_plan_dropdown_items(selected = nil)
    options = [['All', nil]]
    MembershipPlan.all.order(:name).each do |membership_plan|
      options << [membership_plan.name, membership_plan.id]
    end
    options_for_select(options, selected)
  end

  def notification_method_dropdown_items(supplier_id)
    supplier = Supplier.find(supplier_id)
    supplier.notification_methods.active.map do |notification_method|
      "<option value='#{notification_method.id}'>#{notification_method.label} - #{notification_method.value} (#{notification_method.notification_type})</option>"
    end.join
  end

  def supplier_dropdown_items
    Supplier.active.includes(:region).order(name: :asc).each_with_object({}) do |supplier, options|
      region_name = supplier.region&.slug || 'No Region'
      options[region_name] ||= []
      options[region_name] << [supplier.name, supplier.id]
      options
    end
  end

  def supplier_location_dropdown_items
    Supplier.all.order(name: :asc).each_with_object({}) do |supplier, options|
      supplier_data = {
        id: supplier.id,
        coords: [supplier.address&.latitude, supplier.address&.longitude]
      }.to_json
      (options[supplier.address&.city] ||= []) << [supplier.name, supplier_data]
      options
    end
  end

  def order_state_dropdown_items
    Order.machine_class.states.map { |o| [o.titleize, o] }
  end

  def display_time(time, supplier)
    return unless time

    string = time.strftime('%a %m/%d/%y %l:%M %p %Z')
    string << " (#{time.in_time_zone(supplier&.timezone).strftime('%I:%M%P %Z')})" if different_timezone?(supplier&.timezone)
    string
  end

  def different_timezone?(timezone)
    timezone != ENV['TZ']
  end

  def late_scheduled_order?(shipment)
    (shipment.scheduled? || shipment.paid?) && shipment.scheduled_for < Time.zone.now
  end

  def percentage(value, total)
    (100.0 / total.to_f) * value.to_f
  end

  def fraud_status(order)
    return 'pending' unless order.fraud_score
    return 'fail' if order.fraud_score.ml_prediction && order.fraud_score.ml_confidence
    return 'pass' if !order.fraud_score.ml_prediction && order.fraud_score.ml_confidence

    'error'
  end

  def order_adjustment_reasons_for_select(shipment_canceled: false)
    reasons = OrderAdjustmentReason.active
    reasons = if shipment_canceled
                reasons.financial_impact_reasons
              else
                reasons.adjustment_reasons
              end
    reasons = reasons.map do |reason|
      [reason.name, reason.id, { 'data-owed-to-minibar' => reason.owed_to_minibar, 'data-owed-to-supplier ' => reason.owed_to_supplier }]
    end
    options_for_select(reasons)
  end

  def errors_for_transaction(transaction)
    return unless transaction&.metadata&.[](:errors)

    transaction.metadata[:errors].map { |e| ChargeError.new(e[:attribute], e[:code], e[:message]) }
  end

  def transaction_details(metadata)
    html_entities = %w[status amount type cvv_response_code gateway_rejection_reason processor_authorization_code processor_response_code processor_response_text additional_processor_response id].reject { |key| metadata[key].nil? }.map do |attribute|
      "<strong>#{attribute}</strong>: #{attribute == 'amount' ? number_to_currency(metadata[attribute]) : metadata[attribute]}"
    end
    html_entities.join('<br />').html_safe
  end

  class ChargeError < Struct.new(:attribute, :code, :message)
    def to_s
      "#{attribute}: #{code} - #{message}"
    end
  end

  def initial_brand(user)
    return nil unless user.brand_content_manager

    user.brand_content_manager.brand
  end

  def select_product_volume(product)
    volumes = []
    volumes.push(product.volume_unit) if product.volume_unit.present?
    volumes << PRODUCT_VOLUMES
    volumes.flatten!.uniq
  end
end
# rubocop:enable  Metrics/ModuleLength
