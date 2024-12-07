module CustomerNotifierHelper
  def order_survey_url(order_survey, score = nil)
    url = "https://minibardelivery.com/survey/#{order_survey.token}"
    url += "/#{score.to_i}" if score
    url
  end

  # TODO: ...
  def format_code(code)
    "<b style='font-weight:bold; color:#333;'>#{String(code).upcase}</b>"
  end

  def first_or_last_item(items, index)
    return 'first' if index.zero?
    return 'last' if index == items.length - 1
  end

  def on_demand_details(order)
    shipment_count = order.shipments.size

    if order.shipments.any?(&:scheduled_for)
      string = if shipment_count > 1
                 "Your order is arriving in #{shipment_count} parts."
               else
                 "You’ve scheduled delivery for #{format_time_range(order.shipments.first.scheduled_for, order.shipments.first.shipping_method.scheduled_interval_size, order.shipments.first.supplier.timezone)} #{order.shipments.first.scheduled_for.strftime('%A, %b %e')}."
               end
    else
      closed_supplier = order.shipments.any? { |shipment| shipment.shipping_method.closed?(order.completed_at) }
      if closed_supplier
        opening_times = order.shipments.map do |shipment|
          shipment.shipping_method.opens_at(order.completed_at).in_time_zone(shipment.supplier.timezone).strftime('%l:%M%P %A') if shipment.supplier && shipment.shipping_method.opens_at && shipment.shipping_method.closed?
        end.compact

        string = if shipment_count > 1
                   "<b>One or more of our suppliers are currently closed.</b> These items will be delivered after the store opens at #{opening_times.first&.squish}."
                 else
                   "<b>Our supplier is now closed.</b> Your order will be delivered after the store opens at #{opening_times.first&.squish}."
                 end
      else
        string = if shipment_count > 1
                   "Your order is arriving in #{shipment_count} parts."
                 else
                   'Your order will be out the door and on its way shortly.'
                 end
      end
    end
    string
  end

  def format_time_range(time, interval_size = 120, timezone = nil)
    time = time.in_time_zone(timezone) unless timezone.nil?
    interval_start = time
    interval_end   = time + interval_size.minutes

    not_on_the_hour = (interval_start.min + interval_end.min).nonzero?
    spans_am_and_pm = interval_start.hour < 12 && interval_end.hour >= 12 || interval_start.hour >= 12 && interval_end.hour < 12

    if not_on_the_hour
      if spans_am_and_pm
        "#{interval_start.strftime('%l:%M%P').squish}-#{interval_end.strftime('%l:%M%P').squish}"
      else
        "#{interval_start.strftime('%l:%M').squish}-#{interval_end.strftime('%l:%M%P').squish}"
      end
    elsif spans_am_and_pm
      "#{interval_start.strftime('%l%P').squish}-#{interval_end.strftime('%l%P').squish}"
    else
      "#{interval_start.strftime('%l').squish}-#{interval_end.strftime('%l%P').squish}"
    end
  end

  # TODO: Why are we not just using i18n for this?
  def format_abandon_cart_offer(_offer)
    "Use promo code <strong>#{@offer[:code]}</strong> and get $#{@offer[:discount]} off #{@offer[:order]}"
  end

  def format_loyalty_program_module_content(loyalty_program_module_content)
    "You're <strong>#{loyalty_program_module_content[:points_left]} #{'order'.pluralize(loyalty_program_module_content[:points_left])}</strong> away from a discount!"
  end
end
