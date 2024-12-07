class DeliveryTracking
  def initialize(shipment_id)
    if Feature[:trak].enabled?
      Rails.logger.info("Trak: Initializing for Shipment #{shipment_id}")

      @shipment = Shipment.includes(%i[order supplier]).find(shipment_id)
      @supplier = @shipment.supplier

      if @supplier.trak?
        @client   = client
        @order    = @shipment.order

        create_recipient    unless @order.user.trak?
        create_destination  unless @order.ship_address&.trak?
        create_task
      end
    end
  end

  private

  def client
    Trak::Client.new(Settings.trak.api_key)
  end

  def create_recipient
    Rails.logger.info('Trak: Creating New Recipient')
    user = @order.user

    response = client.post('/api/v2/recipients', name: user.name, phone: @order.ship_address&.phone)

    if response['id']
      user.update(trak_id: response['id'])
    else
      Rails.logger.error(response)
    end
  end

  def create_destination
    Rails.logger.info('Trak: Creating New Destination')
    address = @order.ship_address

    response = client.post('/api/v2/destinations', address: {
                                                     number: address.address1.split(' ')[0],
                                                     street: address.address1.split(' ').slice(1, 10).join(' '),
                                                     apartment: address.address2 || '',
                                                     city: address.city,
                                                     state: address.state_name,
                                                     postalCode: address.zip_code,
                                                     country: 'USA'
                                                   },
                                                   location: [address.longitude, address.latitude])

    if response['id']
      address.update(trak_id: response['id'])
    else
      Rails.logger.error(response)
    end
  end

  def create_task
    Rails.logger.info('Trak: Creating New Task')

    response = client.post('/api/v2/tasks', task_options)

    if response['id']
      @shipment.update(trak_id: response['id'])
    else
      Rails.logger.error(response)
    end
  end

  def task_options
    {
      executor: @shipment.supplier.onfleet_organization,
      destination: @order.ship_address&.trak_id,
      recipients: [@order.user.trak_id],
      notes: formatted_delivery_notes,
      pickupTask: false,
      completeBefore: complete_before,
      completeAfter: complete_after,
      metadata: [{
        name: '_receivingTeam',
        type: 'string',
        value: @shipment.supplier.trak_id,
        visibility: ['api']
      }]
    }.merge!(auto_assign_options)
  end

  def auto_assign_options
    return {} if @shipment.scheduled_for || @shipment.supplier.onfleet_autoassign_team.blank?

    {
      autoAssign: {
        mode: 'load',
        team: @shipment.supplier.onfleet_autoassign_team
      }
    }
  end

  def formatted_delivery_notes
    s = "Minibar Order ##{@order.number}\n\n"
    @shipment.order_items.group_by(&:variant).each do |variant, items|
      s << "#{items.sum(&:quantity)} x #{variant.product_size_grouping.name} (#{variant.item_volume}) @ $#{items.sum(&:total).to.f.round_at(2)}\n"
    end
    s << "\n"
    if @order.gift?
      s << "THIS IS A GIFT ORDER FOR #{String(@order.gift_detail.recipient_name).upcase}. GIFT NOTE:\n\n"
      s << "#{@order.gift_detail.message}\n\n"
    end
    s << "DELIVERY NOTES: \n\n #{@order.delivery_notes}\n\n"
    s << "PLEASE CHECK ID ON DELIVER - MIN DATE OF BIRTH #{21.years.ago.strftime('%B %e, %Y').to_s.upcase}"
  end

  def complete_before
    (@shipment.scheduled_for ? @shipment.scheduled_for + @shipment.shipping_method.scheduled_interval_size.minutes : @shipment.shipping_method.maximum_delivery_expectation.minutes.since).in_time_zone(@supplier.timezone).to_i * 1000
  end

  def complete_after
    (@shipment.scheduled_for || Time.zone.now).in_time_zone(@supplier.timezone).to_i * 1000
  end
end
