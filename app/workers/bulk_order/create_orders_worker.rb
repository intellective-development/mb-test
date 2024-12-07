class BulkOrder::CreateOrdersWorker
  include Sidekiq::Worker
  include WorkerErrorHandling
  include BulkOrderDataCsv
  include GuestAuthenticable

  sidekiq_options queue: 'bulk_order', lock: :until_and_while_executing, retry: 3

  def remove_current_orders(bulk_order = nil)
    bulk_order ||= @bulk_order
    bulk_order.orders.destroy_all
    bulk_order.carts.destroy_all
    bulk_order.bulk_order_orders.destroy_all
  end

  def fetch_product(supplier_id, product_id, has_engraving)
    variants = Variant.active.where(supplier_id: supplier_id, product_id: product_id)

    # do we need line engraving?
    variants = variants.select { |v| v.options_type.to_sym == :engraving } if @bulk_order.graphic_engraving? && has_engraving

    # do we need graphic engraving?
    variants = variants.select { |v| v.supplier.supports_graphic_engraving == true } if @bulk_order.graphic_engraving? && @bulk_order.logo?

    raise "Can't find a retailer for specified product attributes" if variants.blank?

    variants.first.id
  rescue StandardError => e
    add_product_error(e, product_id)
  end

  def fetch_rsa_products(address, product_id, has_engraving)
    product_id_with_prefix = "PRODUCT-#{product_id}"
    products = RSA::SelectService.call(@bulk_order.storefront_quote.id, nil, nil, address, nil, product_id_with_prefix)
                                 .select { |item| item[:product_id] == product_id.to_i }

    # do we need line engraving?
    products = products.select { |p| p.type == :engraving } if @bulk_order.graphic_engraving? && has_engraving

    # do we need graphic engraving?
    products = products.select { |p| p.supplier.supports_graphic_engraving == true } if @bulk_order.graphic_engraving? && @bulk_order.logo?

    # now return the first product to match
    products.find { |p| p.shipping_method == @bulk_order.delivery_method.to_sym } or raise "Can't find a retailer for specified product attributes"
  rescue StandardError => e
    add_product_error(e, product_id)
  end

  def add_product_error(error, product_id)
    graphic_engraving = @bulk_order.graphic_engraving? && @bulk_order.logo?
    line_engraving = @bulk_order.graphic_engraving? && @bulk_order.line1?
    msg = "No product matching {graphic_engraving: #{graphic_engraving}, line_engraving: #{line_engraving}}: #{product_id}"

    Rails.logger.error("#{msg} - Exception: #{error.message}")
    @order_errors << msg
  end

  def add_product_to_cart(cart, user, variant_id, quantity, item_options)
    cart.add_item({ identifier: variant_id,
                    variant_id: variant_id,
                    quantity: quantity,
                    user: user,
                    item_options: item_options })
  end

  def get_order_data_item_options(order_data)
    return unless @bulk_order.graphic_engraving?
    return if order_data['engraving_1'].blank? && @bulk_order.line1.blank? && !@bulk_order.logo?

    options_attr = if order_data['engraving_1'].present?
                     {
                       line1: order_data['engraving_1'].to_s,
                       line2: order_data['engraving_2'].to_s,
                       line3: order_data['engraving_3'].to_s,
                       line4: order_data['engraving_4'].to_s
                     }
                   elsif @bulk_order.line1.present?
                     {
                       line1: @bulk_order.line1.to_s,
                       line2: @bulk_order.line2.to_s,
                       line3: @bulk_order.line3.to_s,
                       line4: @bulk_order.line4.to_s
                     }
                   end

    if @bulk_order.logo?
      options_attr ||= {}
      options_attr = options_attr.merge(graphic_engraving_image: @bulk_order.logo.url)
    end

    options_attr
  end

  def create_cart(user, address, storefront, order_data)
    product_id = order_data['product_id']
    quantity = order_data['quantity']
    supplier_id = select_supplier_id(address, order_data)
    has_engraving = (order_data['engraving_1'] || @bulk_order.line1).present?
    cart = Cart.create(storefront: storefront, user: user)

    variant_id = if supplier_id.present?
                   fetch_product(supplier_id, product_id, has_engraving)
                 else
                   # fetch product from RSA
                   fetch_rsa_products(address, product_id, has_engraving)[:variant_id]
                 end

    item_options = get_order_data_item_options(order_data)
    add_product_to_cart(cart, user, variant_id, quantity, item_options)

    cart
  rescue StandardError => e
    @order_errors ||= []
    @order_errors << 'Adding to Cart Error. '

    cart
  end

  def select_supplier_id(address, order_data)
    return order_data['supplier_id'] if order_data['supplier_id'].present?

    @bulk_order.supplier_ids.each do |supplier_id|
      return supplier_id if Supplier.find(supplier_id).delivery_zones.any? { |dz| dz.type == 'DeliveryZoneState' && dz.value == address.state_name }
    end

    nil
  end

  def set_bulk_order(bulk_order_id)
    @bulk_order = BulkOrder.find(bulk_order_id)
  end

  def process_order_data
    # safe guard to not work if bulk order is in any other state then active
    unless @bulk_order.active?
      Rails.logger.error("Error on processing Bulk order: order is not active. Current state is #{@bulk_order.status}")
      return false
    end

    @bulk_order.in_progress!

    remove_current_orders

    invoice_user = create_user_with_params!(@bulk_order.storefront_quote.id, { contact_email: @bulk_order.billing_email })
    order_user = create_user_with_params!(@bulk_order.storefront.id,
                                          {
                                            contact_email: @bulk_order.billing_email,
                                            first_name: @bulk_order.billing_first_name,
                                            last_name: @bulk_order.billing_last_name
                                          })

    order_data = parse_raw_csv(@bulk_order.csv)
    order_data.each do |row|
      # clean up order errors
      @order_errors = []

      invoice_address = create_address(row, invoice_user)
      order_address = create_address(row, order_user)

      invoice_cart = create_cart(invoice_user, invoice_address, @bulk_order.storefront_quote, row)
      order_cart = create_cart(order_user, order_address, @bulk_order.storefront, row)

      gift_options = {
        recipient_name: "#{row['first_name']} #{row['last_name']}",
        recipient_phone: (row['phone']).to_s,
        recipient_email: (row['email']).to_s,
        message: (row['gift_message']).to_s
      }

      invoice_order = create_order(invoice_address, invoice_cart, invoice_user)
      order = create_order(order_address, order_cart, order_user, gift_options)

      create_bulk_order_order(order_user, order_address, order_cart, row, invoice_order, order)

      begin
        # cancel invoice order
        invoice_order.cancel!
      rescue StandardError => e
        Rails.logger.error("Error cancelling invoice order: #{e.message}")
      end
    end
  rescue StandardError => e
    @bulk_order.active!
    raise e
  ensure
    @bulk_order.active!
  end

  def perform_with_error_handling(bulk_order_id)
    set_bulk_order(bulk_order_id)
    process_order_data
  end

  def create_address(data, user)
    address = Address.new(name: "#{data['first_name']} #{data['last_name']}",
                          address_purpose: Address.address_purposes[:shipping],
                          addressable_type: 'User',
                          addressable: user,
                          address1: data['address'],
                          address2: data['address_info'],
                          email: data['email'],
                          city: data['city'],
                          state_name: data['state'],
                          zip_code: data['zip'],
                          phone: data['phone'])
    address.save!
    address
  end

  def create_order(address, cart, user, gift_options = {})
    storefront = cart.storefront
    order = user.orders.new(storefront: storefront, cart_id: cart.id, ship_address: address, email: @bulk_order.billing_email)
    order_params = { cart_id: cart.id, gift_options: gift_options }

    begin
      order_service = OrderCreationServices.new(order, user, cart, order_params, skip_scheduling_check: true, skip_in_stock_check: order.disable_in_stock_check? || true)
      order_service.build_order
    rescue StandardError => e
      @order_errors << "Building Order Error. #{e.message}"
    end

    order.save!
    order.order_amount&.save!

    begin
      order.recalculate_and_apply_taxes
    rescue StandardError => e
      @order_errors << "Building Order Error. #{e.message}"
    end

    if @bulk_order.logo?
      order.shipments.each do |shipment|
        shipment.comments.append Comment.create(note: "Logo: #{@bulk_order.logo.url}")
      end
    end

    order
  end

  private

  def create_bulk_order_order(user, address, cart, data, invoice_order, order)
    bulk_order_order = @bulk_order.bulk_order_orders.new(bulk_order: @bulk_order,
                                                         order: order,
                                                         user: user,
                                                         cart: cart,
                                                         address: address,
                                                         first_name: data['first_name'],
                                                         last_name: data['last_name'],
                                                         company: data['company'],
                                                         phone: data['phone'],
                                                         gift_message: data['gift_message'],
                                                         gift_from: data['gift_from'],
                                                         quantity: data['quantity'],
                                                         email: data['email'],
                                                         product_id: data['product_id'],
                                                         invoice_total: invoice_order&.total_before_discounts,
                                                         invoice_taxes: invoice_order&.amounts&.sales_tax,
                                                         invoice_subtotal: invoice_order&.sub_total_with_engraving,
                                                         invoice_delivery: invoice_order&.shipping_charges,
                                                         invoice_tip_amount: invoice_order&.tip_amount,
                                                         invoice_service_fee: invoice_order&.service_fee,
                                                         invoice_bag_fee: invoice_order&.bag_fee,
                                                         order_errors: @order_errors.join(','))
    bulk_order_order.save!
    bulk_order_order
  end
end
